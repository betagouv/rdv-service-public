# frozen_string_literal: true

require "swagger_helper"

describe "Invitations API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/invitations/{invitation_token}" do
    get "Récupérer un·e usager·ère" do
      with_authentication

      tags "Invitation", "User"
      produces "application/json"
      operationId "getUserByInvitationToken"
      description "Renvoie un·e usager·ère grâce à son jeton d'invitation à prendre rendez-vous"

      parameter name: :invitation_token, in: :path, type: :string, description: "Jeton d'invitation pour un rendez-vous", example: "abcdef123456"

      let!(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Renvoie l'usager·ère" do
        let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation], email: "jean@jacques.fr") }
        let!(:invitation_token) do
          user.assign_rdv_invitation_token
          user.save!
          user.rdv_invitation_token
        end

        schema "$ref" => "#/components/schemas/user_with_root"

        run_test!

        it { expect(parsed_response_body[:user][:id]).to eq(user.id) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized" do
        let(:invitation_token) { "abcd" }
      end

      it_behaves_like "an endpoint that returns 404 - not found", "l'usager·ère n'est pas trouvé·e" do
        let(:invitation_token) { "abcd" }
      end
    end
  end

  path "/api/v1/invitations/rdv_invitation_token", document: false do
    post "Retourne un token d'invitation à prendre rdv pour un·e usager·ère (et le créé si il n'existe pas)" do
      with_authentication

      tags "Invitation", "User"
      produces "application/json"
      operationId "createRdvInvitationToken"
      description "Retourne un token d'invitation à prendre rdv pour un·e usager·ère (et le créé si il n'existe pas)"

      parameter name: :user_id, in: :query, type: :integer, description: "ID de l'usager·ère", example: 123, required: true

      let!(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      let!(:user_id) { user.id }

      response 200, "Renvoie le token" do
        let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation], email: "jean@jacques.fr") }

        schema "$ref" => "#/components/schemas/invitation"

        run_test!

        it { expect(parsed_response_body[:invitation_token]).to eq(user.reload.rdv_invitation_token) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized" do
        let!(:user) { instance_double(User, id: "123") }
      end

      it_behaves_like "an endpoint that returns 403 - forbidden", "l'usager·ère est lié·e à une autre organisation" do
        let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [create(:organisation)]) }
      end
    end
  end
end
