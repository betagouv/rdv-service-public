RSpec.describe Agents::PagesController, type: :controller do
  describe "#home" do
    let(:agent) { create(:agent) }

    before do
      sign_in agent
    end

    context "quand un id de session Crisp est présent" do
      stub_env_with(CRISP_WEBSITE_ID: "abcde")

      it "l’utilisateur est redirigé vers le chat Crisp" do
        get :home, params: { crisp_sid: "123456" }
        expect(response).to redirect_to("https://go.crisp.chat/chat/embed/?website_id=abcde&crisp_sid=123456")
      end
    end
  end
end
