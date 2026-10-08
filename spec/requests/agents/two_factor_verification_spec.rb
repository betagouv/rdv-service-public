RSpec.describe "Vérification récente de la double authentification d'un agent", type: :request do
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, password: "c0rrecThorse!", admin_role_in_organisations: [organisation]) }
  let(:export) do
    create(:export, agent:, organisation_ids: [organisation.id]).tap { _1.store_file("contenu de l'export") }
  end

  def verify_two_factor_by_code!
    post agents_two_factor_verification_path
    post verify_agents_two_factor_verification_path, params: { login_code: { code: LoginCode.last.code } }
  end

  describe "téléchargement d'un export" do
    before { sign_in agent }

    context "quand la double authentification n'a pas été vérifiée" do
      it "redirige vers la page d'explication" do
        get agents_export_download_path(export.id)
        expect(response).to redirect_to(new_agents_two_factor_verification_path)
      end
    end

    context "quand la double authentification a été vérifiée il y a moins de 30 minutes" do
      it "envoie le fichier" do
        verify_two_factor_by_code!
        travel(29.minutes)

        get agents_export_download_path(export.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("contenu de l'export")
      end
    end

    context "quand la double authentification a été vérifiée il y a plus de 30 minutes" do
      it "redirige vers la page d'explication" do
        verify_two_factor_by_code!
        travel(31.minutes)

        get agents_export_download_path(export.id)

        expect(response).to redirect_to(new_agents_two_factor_verification_path)
      end
    end

    context "quand un super admin usurpe l'identité de l'agent" do
      let(:super_admin) { create(:super_admin) }

      before do
        sign_in super_admin
        get sign_in_as_super_admins_agent_path(agent)
      end

      it "envoie le fichier sans exiger la double authentification de l'agent" do
        get agents_export_download_path(export.id)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "vérification par code envoyé par email" do
    before { sign_in agent }

    it "affiche la page d'explication sans envoyer de code" do
      expect { get new_agents_two_factor_verification_path }.not_to change(LoginCode, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Recevoir un code par email")
    end

    it "envoie le code seulement quand l'agent le demande" do
      expect { post agents_two_factor_verification_path }
        .to change(LoginCode, :count).by(1)
        .and have_enqueued_mail(Agents::LoginCodeMailer, :login_code)

      expect(LoginCode.last.email).to eq(agent.email)
      expect(response).to redirect_to(code_agents_two_factor_verification_path)
    end

    it "affiche le formulaire de saisie sans envoyer de nouveau code" do
      post agents_two_factor_verification_path

      expect { get code_agents_two_factor_verification_path }.not_to change(LoginCode, :count)
      expect(response).to have_http_status(:ok)
    end

    it "renvoie vers la page d'explication quand aucun code n'a été envoyé" do
      get code_agents_two_factor_verification_path
      expect(response).to redirect_to(new_agents_two_factor_verification_path)
    end

    it "renvoie un nouveau code et débloque le contact auprès de Brevo" do
      unblock = instance_double(UnblockBrevoTransactionalContact, call: true)
      allow(UnblockBrevoTransactionalContact).to receive(:new).with(agent.email).and_return(unblock)

      expect { post resend_agents_two_factor_verification_path }
        .to change(LoginCode, :count).by(1)
        .and have_enqueued_mail(Agents::LoginCodeMailer, :login_code)

      expect(unblock).to have_received(:call)
      expect(response).to redirect_to(code_agents_two_factor_verification_path)
    end

    context "avec un code valide" do
      it "marque le code comme utilisé" do
        verify_two_factor_by_code!
        expect(LoginCode.last.used_at).to be_present
      end

      it "redirige vers la liste des exports avec un message quand l'agent voulait télécharger un export" do
        get agents_export_download_path(export.id)
        verify_two_factor_by_code!

        expect(response).to redirect_to(agents_exports_path)
        expect(flash[:success]).to be_present
      end

      it "redirige vers la liste des exports quand aucune page n'a été demandée" do
        verify_two_factor_by_code!
        expect(response).to redirect_to(agents_exports_path)
      end
    end

    context "avec un code invalide" do
      it "réaffiche le formulaire et ne donne pas accès aux exports" do
        post agents_two_factor_verification_path
        post verify_agents_two_factor_verification_path, params: { login_code: { code: "000000" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Code à 6 chiffres")

        get agents_export_download_path(export.id)
        expect(response).to redirect_to(new_agents_two_factor_verification_path)
      end
    end
  end

  describe "vérification via ProConnect" do
    stub_env_for_proconnect

    let(:code) { "IDej8hpYou2rZLsDgTzZ_nMl1aXmNajpByd20dig4e8" }
    let(:user_info) do
      {
        "sub" => "ab70770d-1285-46e6-b4d0-3601b49698d4",
        "email" => agent.email,
        "given_name" => "Francis Factice",
        "usual_name" => "Factice",
        "siret" => "13002526500013",
        "idp_id" => "fia1",
        "aud" => "4ec41582-1d60-4f12-a63b-d8abaace16ba",
        "exp" => 1717595030, "iat" => 1717594970, "iss" => "https://fca.integ01.dev-agentconnect.fr/api/v2",
      }
    end
    let(:agent) do
      create(:agent, admin_role_in_organisations: [organisation], pro_connect_openid_sub: "ab70770d-1285-46e6-b4d0-3601b49698d4", pro_connect_2fa_active: true)
    end

    before do
      sign_in agent
      get agents_export_download_path(export.id)
    end

    def verify_two_factor_with_pro_connect!
      post agents_two_factor_verification_path
      state = Rack::Utils.parse_query(URI.parse(response.headers["Location"]).query)["state"]
      get pro_connect_callback_path(state:, code:)
    end

    it "propose de continuer vers ProConnect" do
      get new_agents_two_factor_verification_path
      expect(response.body).to include("Continuer vers ProConnect")
    end

    it "redirige vers ProConnect en exigeant le 2FA, sans envoyer de code" do
      expect { post agents_two_factor_verification_path }.not_to change(LoginCode, :count)

      expect(response).to redirect_to(start_with("https://fca.integ01.dev-agentconnect.fr/api/v2/authorize?"))
      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(response.headers["Location"]).query)
      expect(redirect_url_query_params.symbolize_keys).to include(
        login_hint: agent.email,
        claims: {
          id_token: {
            acr: {
              essential: true,
              values: %w[eidas0-mfa eidas1-mfa eidas2 eidas3],
            },
          },
        }.to_json
      )
    end

    context "quand la double authentification a bien eu lieu" do
      before { ProConnectStubs.stub_callback_requests(code, user_info, with_2fa: true, host: "http://www.example.com") }

      it "redirige vers la liste des exports avec un message et donne accès aux exports" do
        verify_two_factor_with_pro_connect!

        expect(response).to redirect_to(agents_exports_path)
        expect(flash[:success]).to be_present

        get agents_export_download_path(export.id)
        expect(response).to have_http_status(:ok)
      end

      it "ne modifie pas l'agent" do
        expect { verify_two_factor_with_pro_connect! }.not_to change { agent.reload.updated_at }
      end
    end

    context "quand la double authentification n'a pas eu lieu" do
      before { ProConnectStubs.stub_callback_requests(code, user_info, host: "http://www.example.com") }

      it "affiche une erreur, redirige vers la page d'explication et ne donne pas accès aux exports" do
        verify_two_factor_with_pro_connect!

        expect(flash[:error]).to be_present
        expect(response).to redirect_to(new_agents_two_factor_verification_path)

        get agents_export_download_path(export.id)
        expect(response).to redirect_to(new_agents_two_factor_verification_path)
      end
    end

    context "quand le sub ProConnect ne correspond pas à celui de l'agent connecté" do
      before { ProConnectStubs.stub_callback_requests(code, user_info.merge("sub" => "autre_sub"), with_2fa: true, host: "http://www.example.com") }

      it "ne donne pas accès aux exports" do
        verify_two_factor_with_pro_connect!

        expect(response).to redirect_to(new_agents_two_factor_verification_path)

        get agents_export_download_path(export.id)
        expect(response).to redirect_to(new_agents_two_factor_verification_path)
      end
    end
  end

  describe "effacement de la vérification" do
    before do
      sign_in agent
      verify_two_factor_by_code!
    end

    it "efface la vérification à la déconnexion" do
      delete destroy_agent_session_path
      expect(session[:agent_2fa_verified_at]).to be_nil
    end

    context "quand un agent ProConnect tente de se connecter par mot de passe" do
      before do
        agent.update!(pro_connect_openid_sub: "some-sub")
        # Retire uniquement l'agent connecté, comme un `sign_out` Devise : le reste de la session est conservé
        logout(:agent)
      end

      it "efface la vérification" do
        post agent_session_path, params: { agent: { email: agent.email, password: "c0rrecThorse!" } }
        expect(session[:agent_2fa_verified_at]).to be_nil
      end
    end

    context "quand un agent au compte sensible se connecte par mot de passe" do
      before do
        agent.update!(sensitive_account: true)
        logout(:agent)
      end

      it "efface la vérification" do
        post agent_session_path, params: { agent: { email: agent.email, password: "c0rrecThorse!" } }
        expect(session[:agent_2fa_verified_at]).to be_nil
      end
    end
  end
end
