# frozen_string_literal: true

describe InclusionConnectController, type: :controller do
  let(:base_url) { "https://test.inclusion.connect.fr" }

  stub_sentry_events

  describe "#callback" do
    it "update first_name and last_name of agent" do
      now = Time.zone.parse("2022-08-22 11h34")
      travel_to(now)
      agent = create(:agent, :invitation_not_accepted, first_name: nil, last_name: nil, email: "bob@demo.rdv-solidarites.fr")

      stub_const("InclusionConnect::IC_CLIENT_ID", "truc")
      stub_const("InclusionConnect::IC_CLIENT_SECRET", "truc secret")
      stub_const("InclusionConnect::IC_BASE_URL", base_url)

      stub_token_request.to_return(status: 200, body: { access_token: "zekfjzeklfjl", expires_in: now + 1.week, scopes: "openid" }.to_json, headers: {})

      stub_request(:get, "#{base_url}/userinfo?schema=openid").with(
        headers: {
          "Expect" => "",
          "Authorization" => "Bearer zekfjzeklfjl",
          "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus",
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

      # Error message is sent to Sentry
      expect(sentry_events.last.message).to include("InclusionConnect states do not match")
      expect(sentry_events.last.extra.keys).to match_array(%i[params_state session_ic_state])
    end

    it "uses the current domain's support email address in the error message" do
      request.host = "www.rdv-mairie-test.localhost"
      get :callback, params: { state: "zefjzelkf", session_state: "zfjzerklfjz", code: "klzefklzejlf" }
      expect(flash[:error]).to include("support@rdv-mairie.fr")
    end

    it "returns an error if token request error" do
      stub_const("InclusionConnect::IC_CLIENT_ID", "truc")
      stub_const("InclusionConnect::IC_CLIENT_SECRET", "truc secret")
      stub_const("InclusionConnect::IC_BASE_URL", base_url)

      stub_token_request.to_return(status: 500, body: { error: "an error occurs" }.to_json, headers: {})

      session[:ic_state] = "a state"
      get :callback, params: { state: "a state", session_state: "a state", code: "klzefklzejlf" }
      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to eq("Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste.")

      # HTTP request is sent to Sentry as breadcrumbs
      expect(sentry_events.last.breadcrumbs.compact.map(&:message)).to eq(["HTTP request", "HTTP response"])
    end

    it "returns an error if token request doesn't contains token" do
      stub_const("InclusionConnect::IC_CLIENT_ID", "truc")
      stub_const("InclusionConnect::IC_CLIENT_SECRET", "truc secret")
      stub_const("InclusionConnect::IC_BASE_URL", base_url)

      stub_token_request.to_return(status: 200, body: {}.to_json, headers: {})

      session[:ic_state] = "a state"
      get :callback, params: { state: "a state", session_state: "a state", code: "klzefklzejlf" }

      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to eq("Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste.")

      # HTTP request is sent to Sentry as breadcrumbs
      expect(sentry_events.last.breadcrumbs.compact.map(&:message)).to eq(["HTTP request", "HTTP response"])
    end

    it "returns an error if userinfo request doesnt work" do
      stub_const("InclusionConnect::IC_CLIENT_ID", "truc")
      stub_const("InclusionConnect::IC_CLIENT_SECRET", "truc secret")
      stub_const("InclusionConnect::IC_BASE_URL", base_url)

      stub_token_request.to_return(status: 200, body: { access_token: "zekfjzeklfjl", expires_in: "", scopes: "openid" }.to_json, headers: {})

      stub_request(:get, "#{base_url}/userinfo?schema=openid").with(
        headers: {
          "Expect" => "",
          "Authorization" => "Bearer zekfjzeklfjl",
          "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus",
        }
      ).to_return(status: 500, body: "", headers: {})

      session[:ic_state] = "a state"
      get :callback, params: { state: "a state", session_state: "a state", code: "klzefklzejlf" }

      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to eq("Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste.")

      # HTTP request is sent to Sentry as breadcrumbs
      expect(sentry_events.last.breadcrumbs.compact.map(&:message).uniq).to eq(["HTTP request", "HTTP response"])
    end

    it "returns an error if userinfo's email checked is false" do
      stub_const("InclusionConnect::IC_CLIENT_ID", "truc")
      stub_const("InclusionConnect::IC_CLIENT_SECRET", "truc secret")
      stub_const("InclusionConnect::IC_BASE_URL", base_url)

      stub_token_request.to_return(status: 200, body: { access_token: "zekfjzeklfjl", expires_in: "", scopes: "openid" }.to_json, headers: {})

      stub_request(:get, "#{base_url}/userinfo?schema=openid").with(
        headers: {
          "Expect" => "",
          "Authorization" => "Bearer zekfjzeklfjl",
          "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus",
        }
      ).to_return(status: 200, body: { email_verified: false, given_name: "Bob", family_name: "Eponge", email: "bob@demo.rdv-solidarites.fr" }.to_json, headers: {})

      session[:ic_state] = "a state"
      get :callback, params: { state: "a state", session_state: "a state", code: "klzefklzejlf" }

      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to eq("Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste.")

      # HTTP request is sent to Sentry as breadcrumbs
      expect(sentry_events.last.breadcrumbs.compact.map(&:message).uniq).to eq(["HTTP request", "HTTP response"])
    end

    it "call sentry about authentification failure" do
      stub_const("InclusionConnect::IC_CLIENT_ID", "truc")
      stub_const("InclusionConnect::IC_CLIENT_SECRET", "truc secret")
      stub_const("InclusionConnect::IC_BASE_URL", base_url)

      stub_token_request.to_return(status: 500, body: { error: "an error occurs" }.to_json, headers: {})

      session[:ic_state] = "a state"

      expect(Sentry).to receive(:capture_message).with("Failed to authentify agent with inclusionConnect")
      get :callback, params: { state: "a state", session_state: "a state", code: "klzefklzejlf" }
    end
  end

  def stub_token_request
    stub_request(:post, "#{base_url}/token").with(
      body: {
        "client_id" => "truc",
        "client_secret" => "truc secret",
        "code" => "klzefklzejlf",
        "grant_type" => "authorization_code",
        "redirect_uri" => inclusion_connect_callback_url,
      },
      headers: {
        "Expect" => "",
        "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus",
        "Content-Type" => "application/x-www-form-urlencoded",
      }
    )
  end
end
