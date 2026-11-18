RSpec.describe "rate limiting de l'API v1 avec une clé d'API", type: :request do
  include_context "enable rack-attack"

  before do
    klass = Class.new(Api::V1::AgentAuthBaseController) do
      def fake_action
        skip_authorization
        render plain: "ok"
      end
    end
    stub_const("Api::V1::TestController", klass)

    Rails.application.routes.disable_clear_and_finalize = true
    Rails.application.routes.draw do
      get "/api/v1/test/fake_action", to: "api/v1/test#fake_action"
    end
  end

  after { Rails.application.reload_routes! }

  let(:agent) { create(:agent) }
  let!(:api_token) { create(:api_token, agent:) }

  def get_with_api_token(token_value)
    get "/api/v1/test/fake_action", headers: { "Authorization" => "Bearer #{token_value}" }, as: :json
  end

  it "throttle une même clé d'API après 2 requêtes en test" do
    2.times do
      get_with_api_token(api_token.raw_token)
      expect(response).not_to redirect_to("/500.html")
    end

    get_with_api_token(api_token.raw_token)
    expect(response).to redirect_to("/500.html")
  end

  it "throttle par IP même avec des faux tokens rdvsp_pat_ différents (anti brute force)" do
    2.times do |i|
      get_with_api_token("rdvsp_pat_faux_#{i}")
      expect(response).to have_http_status(:unauthorized)
    end

    # chaque faux token a son propre bucket "par clé", mais le bucket par IP bloque la 3e requête
    get_with_api_token("rdvsp_pat_faux_2")
    expect(response).to redirect_to("/500.html")
  end
end
