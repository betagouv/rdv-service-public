RSpec.describe Agents::ExportsController, type: :controller do
  render_views

  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let(:export) do
    create(:export, agent:, organisation_ids: [organisation.id]).tap { _1.store_file("contenu de l'export") }
  end

  before { sign_in agent }

  describe "#index" do
    it "expose l'export à télécharger automatiquement quand il appartient à l'agent" do
      get :index, params: { auto_download_export_id: export.id }
      expect(assigns(:auto_download_export)).to eq(export)
      meta_refresh = Capybara.string(response.body).find("meta[http-equiv='refresh']", visible: false)
      expect(meta_refresh[:content]).to eq("0; url=#{agents_export_download_path(export.id)}")
    end

    it "n'expose aucun export à télécharger automatiquement pour un export d'un autre agent" do
      other_export = create(:export)
      get :index, params: { auto_download_export_id: other_export.id }
      expect(assigns(:auto_download_export)).to be_nil
    end

    it "n'expose aucun export à télécharger automatiquement par défaut" do
      get :index
      expect(assigns(:auto_download_export)).to be_nil
    end
  end

  describe "#download" do
    context "quand la double authentification n'a pas été validée récemment" do
      it "redirige vers la page de vérification et mémorise l'URL demandée" do
        get :download, params: { export_id: export.id }

        expect(response).to redirect_to(new_agents_two_factor_verification_path)
        expect(session[:two_factor_step_up_return_to]).to eq(agents_export_download_path(export.id))
      end
    end

    context "quand la double authentification a expiré (plus de 30 minutes)" do
      before { session[:agent_2fa_verified_at] = 31.minutes.ago.iso8601 }

      it "redirige vers la page de vérification" do
        get :download, params: { export_id: export.id }
        expect(response).to redirect_to(new_agents_two_factor_verification_path)
      end
    end

    context "quand la double authentification a été validée récemment" do
      before { session[:agent_2fa_verified_at] = 5.minutes.ago.iso8601 }

      it "envoie le fichier" do
        get :download, params: { export_id: export.id }
        expect(response).to have_http_status(:ok)
      end
    end

    context "quand un super admin usurpe l'identité de l'agent" do
      before { session[:super_admin_signed_in_as_agent] = true }

      it "envoie le fichier sans exiger la double authentification de l'agent" do
        get :download, params: { export_id: export.id }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
