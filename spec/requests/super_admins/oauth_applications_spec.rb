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

      it "ignore les autres attributs envoyés" do
        patch super_admins_oauth_application_path(oauth_application), params: { oauth_application: { name: "Changement", internal_documentation: "Une description" } }

        expect(oauth_application.reload.name).not_to eq("Changement")
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
end
