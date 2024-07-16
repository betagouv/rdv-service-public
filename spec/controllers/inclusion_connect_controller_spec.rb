RSpec.describe InclusionConnectController, type: :controller do
  let(:base_url) { "https://test.inclusion.connect.fr" }

  before do
    stub_const("InclusionConnect::IC_CLIENT_ID", "truc")
    stub_const("InclusionConnect::IC_CLIENT_SECRET", "truc secret")
    stub_const("InclusionConnect::IC_BASE_URL", base_url)
  end

  describe "#auth" do
    it "redirects to InclusionConnect" do
      get :auth
      expect(response).to redirect_to(start_with("#{base_url}/authorize/?"))

      redirect_url = response.headers["Location"]
      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(redirect_url).query)
      expected_params = {
        client_id: "truc",
        from: "community",
        redirect_uri: inclusion_connect_callback_url,
        response_type: "code",
        scope: "openid email profile",
        state: be_a_kind_of(String),
      }
      expect(redirect_url_query_params.symbolize_keys).to match(expected_params)
    end
  end

  describe "#callback" do
    let(:now) { Time.zone.now }
    let(:ic_state) { Digest::SHA1.hexdigest("InclusionConnect - #{SecureRandom.hex(13)}") }

    describe "synchronizing local agent" do
      before do
        stub_token_request.to_return(status: 200, body: { access_token: "zekfjzeklfjl", expires_in: now + 1.week, scopes: "openid" }.to_json, headers: {})

        user_info = {
          given_name: "Bob",
          family_name: "Eponge",
          email: "bob@demo.rdv-solidarites.fr",
          sub: "12345678-90ab-cdef-1234-567890abcdef",
        }

        stub_request(:get, "#{base_url}/userinfo/?schema=openid").with(
          headers: {
            "Authorization" => "Bearer zekfjzeklfjl",
          }
        ).to_return(status: 200, body: user_info.to_json, headers: {})

        session[:ic_state] = ic_state
      end

      context "agent does not exist" do
        it "informs user that she could not be connected" do
          get :callback, params: { state: ic_state, session_state: ic_state, code: "klzefklzejlf" }

          # On aurait envie d'utiliser une feature spec et vérifier le contenu de la page, mais
          # les feature specs ne permettent pas de manipuler la session pour y écrire le ic_state.
          expect(response).to redirect_to("/agents/sign_in")
          expect(flash[:error]).to include(
            "Il n'y a pas de compte agent pour l'adresse mail bob@demo.rdv-solidarites.fr.<br />" \
            "Vous devez utiliser Inclusion Connect avec l'adresse mail à laquelle vous avez reçu votre invitation sur RDV Solidarités.<br />Vous pouvez également contacter le support à l'adresse"
          )
        end
      end

      context "when agent can be found by email but has no sub" do
        it "saves the sub and touches sign in datetimes" do
          agent = create(:agent, :invitation_not_accepted, email: "bob@demo.rdv-solidarites.fr")
          get :callback, params: { state: ic_state, session_state: ic_state, code: "klzefklzejlf" }
          expect(agent.reload).to have_attributes(
            inclusion_connect_open_id_sub: "12345678-90ab-cdef-1234-567890abcdef",
            confirmed_at: be_within(10.seconds).of(now),
            invitation_accepted_at: be_within(10.seconds).of(now),
            last_sign_in_at: be_within(10.seconds).of(now)
          )
        end

        context "when agent has no names" do
          it "fills up the names" do
            agent = create(:agent, first_name: nil, last_name: nil, allow_blank_name: true, email: "bob@demo.rdv-solidarites.fr")
            get :callback, params: { state: ic_state, session_state: ic_state, code: "klzefklzejlf" }
            expect(agent.reload).to have_attributes(
              first_name: "Bob",
              last_name: "Eponge"
            )
          end
        end

        context "when agent already has names" do
          it "update the names" do
            agent = create(:agent, first_name: "Francis", last_name: "Factice", email: "bob@demo.rdv-solidarites.fr")
            get :callback, params: { state: ic_state, session_state: ic_state, code: "klzefklzejlf" }
            expect(agent.reload).to have_attributes(
              first_name: "Bob",
              last_name: "Eponge"
            )
          end
        end
      end

      context "agent can be found by sub" do
        let!(:agent) { create(:agent, :invitation_not_accepted, inclusion_connect_open_id_sub: "12345678-90ab-cdef-1234-567890abcdef") }

        it "update last_sign_in_at and logs her in" do
          get :callback, params: { state: ic_state, session_state: ic_state, code: "klzefklzejlf" }

          expect(agent.reload).to have_attributes(
            last_sign_in_at: be_within(10.seconds).of(now)
          )

          expect(response).to redirect_to(root_path)
        end
      end

      context "email and sub match two different agents" do
        let!(:agent_with_sub) { create(:agent, :invitation_not_accepted, inclusion_connect_open_id_sub: "12345678-90ab-cdef-1234-567890abcdef") }
        let!(:agent_with_email) { create(:agent, :invitation_not_accepted, email: "bob@demo.rdv-solidarites.fr") }

        it "warns Sentry" do
          get :callback, params: { state: ic_state, session_state: ic_state, code: "klzefklzejlf" }

          breadcrumbs = sentry_events.last.breadcrumbs.compact
          expect(breadcrumbs).to include(
            have_attributes(message: "Found agent with sub", data: { sub: "12345678-90ab-cdef-1234-567890abcdef", agent_id: agent_with_sub.id }),
            have_attributes(message: "Found agent with email", data: { email: "bob@demo.rdv-solidarites.fr", agent_id: agent_with_email.id })
          )
        end
      end

      context "email and sub match two different agents but one is deleted" do
        let!(:agent_with_sub) { create(:agent, :invitation_not_accepted, inclusion_connect_open_id_sub: "12345678-90ab-cdef-1234-567890abcdef") }
        let!(:agent_with_email) { create(:agent, :invitation_not_accepted, email: "bob@demo.rdv-solidarites.fr") }

        it "update agent and log in" do
          agent_with_sub.soft_delete
          get :callback, params: { state: ic_state, session_state: ic_state, code: "klzefklzejlf" }
          expect(agent_with_email.reload).to have_attributes(
            last_sign_in_at: be_within(10.seconds).of(now),
            inclusion_connect_open_id_sub: "12345678-90ab-cdef-1234-567890abcdef"
          )

          expect(response).to redirect_to(root_path)
        end
      end
    end

    it "returns an error if state doesn't match" do
      session[:ic_state] = "AZEERT"
      get :callback, params: { state: "zefjzelkf", session_state: "zfjzerklfjz", code: "klzefklzejlf" }
      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to include("Nous n'avons pas pu vous authentifier. Contactez le support à l'adresse")

      # Error message is sent to Sentry
      expect(sentry_events.last.message).to include("InclusionConnect states do not match")
      expect(sentry_events.last.extra.keys).to match_array(%i[params_state session_ic_state])
    end

    it "uses the current domain's support email address in the error message" do
      request.host = "www.rdv-mairie-test.localhost"
      get :callback, params: { state: "zefjzelkf", session_state: "zfjzerklfjz", code: "klzefklzejlf" }
      expect(flash[:error]).to include("support@rdv-service-public.fr")
    end

    it "returns an error if token request error" do
      stub_token_request.to_return(status: 500, body: { error: "an error occurs" }.to_json, headers: {})

      session[:ic_state] = "a state"
      get :callback, params: { state: "a state", session_state: "a state", code: "klzefklzejlf" }
      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to include("Nous n'avons pas pu vous authentifier. Contactez le support à l'adresse")

      # HTTP request is sent to Sentry as breadcrumbs
      expect(sentry_events.last.breadcrumbs.compact.map(&:message)).to eq(["HTTP request", "HTTP response"])
    end

    it "returns an error if token request doesn't contains token" do
      stub_token_request.to_return(status: 200, body: {}.to_json, headers: {})

      session[:ic_state] = "a state"
      get :callback, params: { state: "a state", session_state: "a state", code: "klzefklzejlf" }

      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to include("Nous n'avons pas pu vous authentifier. Contactez le support à l'adresse")

      # HTTP request is sent to Sentry as breadcrumbs
      expect(sentry_events.last.breadcrumbs.compact.map(&:message)).to eq(["HTTP request", "HTTP response"])
    end

    it "returns an error if userinfo request doesnt work" do
      stub_token_request.to_return(status: 200, body: { access_token: "zekfjzeklfjl", expires_in: "", scopes: "openid" }.to_json, headers: {})

      stub_request(:get, "#{base_url}/userinfo/?schema=openid").with(
        headers: {
          "Authorization" => "Bearer zekfjzeklfjl",
        }
      ).to_return(status: 500, body: "", headers: {})

      session[:ic_state] = "a state"
      get :callback, params: { state: "a state", session_state: "a state", code: "klzefklzejlf" }

      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to include("Nous n'avons pas pu vous authentifier. Contactez le support à l'adresse")

      # HTTP request is sent to Sentry as breadcrumbs
      expect(sentry_events.last.breadcrumbs.compact.map(&:message).uniq).to eq(["HTTP request", "HTTP response"])
    end

    it "call sentry about authentification failure" do
      stub_token_request.to_return(status: 500, body: { error: "an error occurs" }.to_json, headers: {})

      session[:ic_state] = "a state"

      get :callback, params: { state: "a state", session_state: "a state", code: "klzefklzejlf" }
      expect(sentry_events.last.message).to eq("Failed to authenticate agent with InclusionConnect - Api error")

      expect(response).to redirect_to(new_agent_session_path)
      expect(flash[:error]).to include("Nous n'avons pas pu vous authentifier. Contactez le support à l'adresse")
    end

    context "call sentry about nil sub and email" do
      before do
        stub_token_request.to_return(status: 200, body: { access_token: "zekfjzeklfjl", expires_in: now + 1.week, scopes: "openid" }.to_json, headers: {})

        user_info = {
          given_name: "Bob",
          family_name: "Eponge",
          email: nil,
          sub: nil,
        }

        stub_request(:get, "#{base_url}/userinfo/?schema=openid").with(
          headers: {
            "Authorization" => "Bearer zekfjzeklfjl",
          }
        ).to_return(status: 200, body: user_info.to_json, headers: {})

        session[:ic_state] = ic_state
      end

      it do
        get :callback, params: { state: ic_state, session_state: ic_state, code: "klzefklzejlf" }
        expect(sentry_events.map(&:message)).to include("InclusionConnect sub is nil", "InclusionConnect email is nil", "Failed to authenticate agent with InclusionConnect - Agent not found")
      end
    end
  end

  def stub_token_request
    stub_request(:post, "#{base_url}/token/").with(
      body: {
        "client_id" => "truc",
        "client_secret" => "truc secret",
        "code" => "klzefklzejlf",
        "grant_type" => "authorization_code",
        "redirect_uri" => inclusion_connect_callback_url,
      },
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded",
      }
    )
  end
end
