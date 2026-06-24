RSpec.describe ProConnectController do # rubocop:disable RSpec/SpecFilePathFormat
  stub_env_for_proconnect

  describe "#callback" do
    let(:state) { auth_client.state }
    let(:auth_client) do
      ProConnectOpenIdClient::Auth.new(
        client_id: "ec41582-1d60-4f11-a63b-d8abaece16aa",
        client_secret: "un faux secret de test"
      )
    end
    let(:code) { "IDej8hpYou2rZLsDgTzZ_nMl1aXmNajpByd20dig4e8" }

    let(:user_info) do
      {
        "sub" => "ab70770d-1285-46e6-b4d0-3601b49698d4",
        "email" => "francis.factice@exemple.gouv.fr",
        "given_name" => "Francis Factice",
        "usual_name" => "Factice",
        "siret" => "13002526500013",
        "idp_id" => "fia1",
        "aud" => "4ec41582-1d60-4f12-a63b-d8abaace16ba",
        "exp" => 1717595030, "iat" => 1717594970, "iss" => "https://fca.integ01.dev-agentconnect.fr/api/v2",
      }
    end

    before do
      session[:pro_connect] = {
        state: state,
        connection_for: "agent",
      }
      ProConnectStubs.stub_callback_requests(code, user_info, host: "http://#{Domain::RDV_SERVICE_PUBLIC.host_name}")

      session[:agent_return_to] = "/agents/edit" # Pour simuler le retour vers la page demandée avant la connexion
    end

    context "quand l'agent s'est connecté sur l'ancien nom de domain et doit être redirigé vers le nouveau" do
      before do
        controller.request.host = Domain::RDV_SERVICE_PUBLIC.host_name
      end

      let!(:agent) do
        create(:agent, admin_role_in_organisations: [organisation], pro_connect_openid_sub: user_info["sub"], email: user_info["email"])
      end

      context "et qu'il doit être redirigé" do
        let(:organisation) { create(:organisation, verticale: :rdv_etat) }

        it "fait la redirection" do
          get :callback, params: { state:, code: }

          expect(response).to redirect_to("http://#{Domain::RDV_SERVICE_PUBLIC_ETAT.host_name}/agents/edit?automatic_redirection_from_other_domain=1")
        end
      end

      context "et qu'il n'a pas besoin d'être redirigé" do
        let(:organisation) { create(:organisation, verticale: :rdv_mairie) }

        it "ne redirige pas" do
          get :callback, params: { state:, code: }

          expect(response).to redirect_to("http://#{Domain::RDV_SERVICE_PUBLIC.host_name}/agents/edit")
        end
      end
    end
  end
end
