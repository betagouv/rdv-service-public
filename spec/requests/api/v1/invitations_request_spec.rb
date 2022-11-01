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
      description "Renvoie un·e usager·ère grâce à son jeton d'invitation"

      parameter name: :invitation_token, in: :path, type: :string, description: "Jeton d'invitation", example: "abcdef123456"

      response 200, "Renvoie l'usager·ère" do
        let!(:organisation) { create(:organisation) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
        let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation], email: "jean@jacques.fr") }
        let!(:invitation_token) do
          user.invite! { |u| u.skip_invitation = true }
          user.raw_invitation_token
        end

        let(:auth_headers) { api_auth_headers_for_agent(agent) }
        let(:"access-token") { auth_headers["access-token"].to_s }
        let(:uid) { auth_headers["uid"].to_s }
        let(:client) { auth_headers["client"].to_s }

        schema "$ref" => "#/components/schemas/user_with_root"

        run_test!

        it { expect(parsed_response_body[:user][:id]).to eq(user.id) }
      end

      response 401, "Problème d'authentification" do
        let(:invitation_token) { "abcd" }

        let(:agent) { create(:agent) }
        let(:auth_headers) { api_auth_headers_for_agent(agent) }
        let(:"access-token") { "false" }
        let(:uid) { auth_headers["uid"].to_s }
        let(:client) { auth_headers["client"].to_s }

        schema "$ref" => "#/components/schemas/error_authentication"

        run_test!
      end

      response 404, "Renvoie 'not_found' quand l'usager·ère n'est pas trouvé·e" do
        let(:invitation_token) { "abcd" }

        let(:agent) { create(:agent) }
        let(:auth_headers) { api_auth_headers_for_agent(agent) }
        let(:"access-token") { auth_headers["access-token"].to_s }
        let(:uid) { auth_headers["uid"].to_s }
        let(:client) { auth_headers["client"].to_s }

        schema "$ref" => "#/components/schemas/error_not_found"

        run_test!
      end
    end
  end
end
