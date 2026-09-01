RSpec.describe Agents::ExportsController, type: :controller do
  let(:agent) { create(:agent) }
  let(:export) do
    create(:export, agent:).tap { _1.store_file("contenu de l'export") }
  end

  before { sign_in agent }

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
  end
end
