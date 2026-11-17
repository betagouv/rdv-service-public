RSpec.describe "SuperAdmins::OauthApplications", type: :request do
  include Rails.application.routes.url_helpers

  let!(:oauth_application) { create(:oauth_application) }

  describe "PATCH /super_admins/oauth_applications/:id" do
    context "quand le super admin est legacy_admin" do
      let(:super_admin) { create(:super_admin) }

      before { login_as(super_admin, scope: :super_admin) }

      it "modifie la documentation interne et versionne le changement avec PaperTrail" do
        patch super_admins_oauth_application_path(oauth_application), params: { oauth_application: { internal_documentation: "Application de prise de RDV" } }

        expect(oauth_application.reload.internal_documentation).to eq("Application de prise de RDV")
        expect(oauth_application.versions.last.whodunnit).to eq(super_admin.name_for_paper_trail)
      end

      it "modifie le name" do
        patch super_admins_oauth_application_path(oauth_application), params: { oauth_application: { name: "Nouveau nom" } }

        expect(oauth_application.reload.name).to eq("Nouveau nom")
      end

      it "ignore les attributs non éditables (uid, secret)" do
        patch super_admins_oauth_application_path(oauth_application), params: { oauth_application: { uid: "changed", secret: "changed" } }

        expect(oauth_application.reload.uid).not_to eq("changed")
      end
    end

    context "quand le super admin est support" do
      let(:super_admin) { create(:super_admin, :support) }

      before { login_as(super_admin, scope: :super_admin) }

      it "refuse la modification" do
        patch super_admins_oauth_application_path(oauth_application), params: { oauth_application: { internal_documentation: "Application de prise de RDV" } }

        expect(oauth_application.reload.internal_documentation).to be_nil
      end
    end
  end

  describe "GET /super_admins/oauth_applications/:id" do
    let(:super_admin) { create(:super_admin) }

    before { login_as(super_admin, scope: :super_admin) }

    it "affiche le bouton de rotation du client_secret" do
      get super_admins_oauth_application_path(oauth_application)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Régénérer le client_secret")
    end
  end

  describe "POST /super_admins/oauth_applications" do
    let(:super_admin) { create(:super_admin) }
    let(:agent) { create(:agent) }

    before { login_as(super_admin, scope: :super_admin) }

    it "crée une application client_credentials avec un agent associé et affiche le secret une seule fois dans le flash" do
      expect do
        post super_admins_oauth_applications_path, params: { oauth_application: { name: "Cron partenaire", grant_type: "client_credentials", agent_id: agent.id, redirect_uri: "" } }
      end.to change(OauthApplication, :count).by(1)

      application = OauthApplication.last
      expect(response).to redirect_to(super_admins_oauth_application_path(application))
      expect(application.grant_type).to eq("client_credentials")
      expect(application.agent).to eq(agent)
      expect(flash[:notice]).to include(application.uid)
      expect(flash[:notice]).to include("client_secret")
    end

    it "refuse une application client_credentials sans agent" do
      expect do
        post super_admins_oauth_applications_path, params: { oauth_application: { name: "Cron sans agent", grant_type: "client_credentials", redirect_uri: "" } }
      end.not_to change(OauthApplication, :count)

      expect(response).to have_http_status(422)
    end

    it "crée une application authorization_code avec un redirect_uri" do
      expect do
        post super_admins_oauth_applications_path, params: { oauth_application: { name: "App web", grant_type: "authorization_code", redirect_uri: "https://example.com/callback" } }
      end.to change(OauthApplication, :count).by(1)

      expect(OauthApplication.last.grant_type).to eq("authorization_code")
    end
  end

  describe "DELETE /super_admins/oauth_applications/:id" do
    let(:super_admin) { create(:super_admin) }

    before { login_as(super_admin, scope: :super_admin) }

    it "supprime l'application et révoque ses tokens" do
      create(:access_token, application: oauth_application)

      expect do
        delete super_admins_oauth_application_path(oauth_application)
      end.to change(OauthApplication, :count).by(-1)

      expect(Doorkeeper::AccessToken.where(application: oauth_application)).to be_empty
    end
  end

  describe "POST /super_admins/oauth_applications/:id/regenerate_secret" do
    let(:super_admin) { create(:super_admin) }
    let(:agent) { create(:agent) }
    let!(:m2m_application) { create(:oauth_application, grant_type: "client_credentials", agent:, redirect_uri: nil) }
    let!(:old_token) { create(:access_token, application: m2m_application, refresh_token: nil) }

    before { login_as(super_admin, scope: :super_admin) }

    it "régénère le secret, révoque les jetons actifs et affiche le nouveau secret une seule fois dans le flash" do
      old_secret = m2m_application.plaintext_secret

      post regenerate_secret_super_admins_oauth_application_path(m2m_application)

      expect(response).to redirect_to(super_admins_oauth_application_path(m2m_application))
      new_secret = flash[:notice].split(": ").last
      expect(flash[:notice]).to include("client_secret")
      expect(new_secret).to be_present
      expect(new_secret).not_to eq(old_secret)

      # l'ancien secret ne permet plus d'obtenir un jeton
      post "/oauth/token", params: { grant_type: "client_credentials", client_id: m2m_application.uid, client_secret: old_secret }
      expect(response).to have_http_status(:unauthorized)

      # le nouveau secret fonctionne
      post "/oauth/token", params: { grant_type: "client_credentials", client_id: m2m_application.uid, client_secret: new_secret }
      expect(response).to have_http_status(:success)

      # les jetons actifs ont été révoqués
      expect(old_token.reload).to be_revoked
    end

    it "est refusé pour un super admin support" do
      login_as(create(:super_admin, :support), scope: :super_admin)

      post regenerate_secret_super_admins_oauth_application_path(m2m_application)

      expect(response).to redirect_to(super_admins_root_path)
    end
  end
end
