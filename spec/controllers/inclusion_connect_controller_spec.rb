# frozen_string_literal: true

BASE_URL = "https://test.inclusion.connect.fr/"

describe InclusionConnectController, type: :controller do
  describe "#callback" do
    it "update first_name and last_name of agent" do
      now = Time.zone.parse("2022-08-22 11h34")
      travel_to(now)
      agent = create(:agent, :invitation_not_accepted, first_name: nil, last_name: nil, email: "bob@demo.rdv-solidarites.fr")

      ENV["INCLUSION_CONNECT_CLIENT_ID"] = "truc"
      ENV["INCLUSION_CONNECT_CLIENT_SECRET"] = "truc secret"
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

      state = "A STATE"
      session[:ic_state] = state

      get :callback, params: { state: state, session_state: state, code: "klzefklzejlf" }

      agent.reload
      expect(agent.first_name).to eq("Bob")
      expect(agent.last_name).to eq("Eponge")
      expect(agent.confirmed_at).to be_within(10.seconds).of(now)
    end

    it "returns an error if state doesn't match" do
      session[:ic_state] = "AZEERT"
      get :callback, params: { state: "zefjzelkf", session_state: "zfjzerklfjz", code: "klzefklzejlf" }
      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to eq("Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste.")
    end

    it "returns an error if token request error" do
      ENV["INCLUSION_CONNECT_CLIENT_ID"] = "truc"
      ENV["INCLUSION_CONNECT_CLIENT_SECRET"] = "truc secret"
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
      ).to_return(status: 500, body: { error: "an error occurs" }.to_json, headers: {})

      session[:ic_state] = "a state"
      get :callback, params: { state: "a state", session_state: "a state", code: "klzefklzejlf" }
      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to eq("Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste.")
    end

    it "returns an error if token request doesn't contains token" do
      ENV["INCLUSION_CONNECT_CLIENT_ID"] = "truc"
      ENV["INCLUSION_CONNECT_CLIENT_SECRET"] = "truc secret"
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
      ).to_return(status: 200, body: { }.to_json, headers: {})

      session[:ic_state] = "a state"
      get :callback, params: { state: "a state", session_state: "a state", code: "klzefklzejlf" }
 
      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to eq("Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste.")
    end

    it "returns an error if userinfo request doesnt work" do
      ENV["INCLUSION_CONNECT_CLIENT_ID"] = "truc"
      ENV["INCLUSION_CONNECT_CLIENT_SECRET"] = "truc secret"
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
      ).to_return(status: 200, body: { access_token: "zekfjzeklfjl", expires_in: "", scopes: "openid" }.to_json, headers: {})

      stub_request(:get, "#{BASE_URL}/userinfo?schema=openid").with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer zekfjzeklfjl",
          "Host" => "test.inclusion.connect.fr",
          "User-Agent" => "Ruby",
        }
      ).to_return(status: 500, body: "", headers: {})

      session[:ic_state] = "a state"
      get :callback, params: { state: "a state", session_state: "a state", code: "klzefklzejlf" }
 
      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to eq("Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste.")
    end

    it "returns an error if userinfo's email checked is false" do
      ENV["INCLUSION_CONNECT_CLIENT_ID"] = "truc"
      ENV["INCLUSION_CONNECT_CLIENT_SECRET"] = "truc secret"
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
      ).to_return(status: 200, body: { access_token: "zekfjzeklfjl", expires_in: "", scopes: "openid" }.to_json, headers: {})

      stub_request(:get, "#{BASE_URL}/userinfo?schema=openid").with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer zekfjzeklfjl",
          "Host" => "test.inclusion.connect.fr",
          "User-Agent" => "Ruby",
        }
      ).to_return(status: 200, body: { email_verified: false, given_name: "Bob", family_name: "Eponge", email: "bob@demo.rdv-solidarites.fr" }.to_json, headers: {})

      session[:ic_state] = "a state"
      get :callback, params: { state: "a state", session_state: "a state", code: "klzefklzejlf" }
 
      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to eq("Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste.")
    end
  end
end
