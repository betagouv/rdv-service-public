RSpec.describe Agents::ProConnectLinkingController, type: :controller do
  render_views

  let(:agent) { create(:agent, email: "francis.factice@exemple.fr") }

  before { sign_in agent }

  describe "#show" do
    it "rend la page d’explication" do
      get :show
      expect(response).to have_http_status(:ok)
    end
  end

  describe "#create" do
    it "déconnecte l’agent et le redirige vers ProConnect avec son email en login_hint" do
      post :create

      expect(response).to redirect_to(pro_connect_auth_path(login_hint: "francis.factice@exemple.fr", user_type: "agent"))
      expect(controller.send(:current_agent)).to be_nil
    end
  end
end
