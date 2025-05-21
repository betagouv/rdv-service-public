RSpec.describe FranceConnectV2Controller do
  stub_env_with(
    FRANCECONNECT_V2_BASE_URL: "https://fcp-low.integ01.dev-franceconnect.fr/api/v2",
    FRANCECONNECT_V2_CLIENT_ID: "un faux client id",
    FRANCECONNECT_V2_CLIENT_SECRET: "un faux client secret"
  )

  describe "#auth" do
    it "redirects to AgentConnect" do
      get :auth

      redirect_url = response.headers["Location"]
      expect(redirect_url).to start_with("https://fcp-low.integ01.dev-franceconnect.fr/api/v2/authorize?")
      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)

      expect(redirect_url_query_params.symbolize_keys).to match(
        acr_values: "eidas1",
        client_id: "un faux client id",
        # TODO: changer pour ""http://test.host/omniauth/franceconnect_v2/callback"" quand on a le bac à sable
        redirect_uri: "https://demo.rdv.numerique.gouv.fr/omniauth/franceconnect_v2/callback",
        response_type: "code",
        scope: "email openid birthdate given_name family_name",
        state: be_a(String),
        nonce: be_a(String)
      )
    end
  end
end
