# frozen_string_literal: true

describe InclusionConnectController, type: :controller do
  describe "#callback" do
    it "update first_name and last_name of agent" do
      now = Time.zone.parse("2022-08-22 11h34")
      travel_to(now)
      agent = create(:agent, :invitation_not_accepted, first_name: nil, last_name: nil, email: "bob@demo.rdv-solidarites.fr")

      ENV["INCLUSION_CONNECT_CLIENT_ID"] = "truc"
      ENV["INCLUSION_CONNECT_CLIENT_SECRET"] = "truc secret"
      BASE_URL = "https://test.inclusion.connect.fr/"
      ENV["INCLUSION_CONNECT_BASE_URL"] = BASE_URL

      stub_request(:post, "#{BASE_URL}/token").with(
        body: {
          "client_id" => "truc",
          "client_secret" => "truc secret",
          "code" => "klzefklzejlf",
          "grant_type" => "authorization_code",
          "redirect_uri" => inclusion_connect_callback_url,
        },
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "test.inclusion.connect.fr",
          "User-Agent" => "Ruby",
        }
      ).to_return(status: 200, body: { access_token: "zekfjzeklfjl", expires_in: now + 1.week, scopes: "openid" }.to_json, headers: {})

      stub_request(:get, "#{BASE_URL}/userinfo?schema=openid").with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer zekfjzeklfjl",
          "Host" => "test.inclusion.connect.fr",
          "User-Agent" => "Ruby",
        }
      ).to_return(status: 200, body: { email_verified: true, given_name: "Bob", family_name: "Eponge", email: "bob@demo.rdv-solidarites.fr" }.to_json, headers: {})

      get :callback, params: { state: "zefjzelkf", session_state: "zfjzerklfjz", code: "klzefklzejlf" }

      agent.reload
      expect(agent.first_name).to eq("Bob")
      expect(agent.last_name).to eq("Eponge")
      expect(agent.confirmed_at).to be_within(10.seconds).of(now)
    end
  end
end
