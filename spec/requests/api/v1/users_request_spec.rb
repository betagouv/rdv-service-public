require "swagger_helper"

RSpec.describe "Users API", swagger_doc: "v1/api.json" do
  with_examples

  let(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  path "/api/v1/users/{user_id}" do
    get "Récupérer un·e usager·ère" do
      with_authentication

      tags "User"
      produces "application/json"
      operationId "getUser"
      description "Renvoie un·e usager·ère"

      parameter name: :user_id, in: :path, type: :integer, description: "ID de l'usager·ère", example: 123

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      let!(:user_id) { user.id }

      response 200, "Renvoie l'usager·ère" do
        let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation], email: "jean@jacques.fr") }

        schema "$ref" => "#/components/schemas/user_with_root"

        run_test!

        it { expect(parsed_response_body[:user][:id]).to eq(user.id) }

        it "logs the API call" do
          expect(ApiCall.first.attributes.symbolize_keys).to include(
            controller_name: "users",
            action_name: "show",
            agent_id: agent.id
          )
        end
      end

      response 200, "authorized user ID also belongs to other organisation", document: false do
        let!(:unauthorized_orga) { create(:organisation) }
        let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation, unauthorized_orga]) }

        schema "$ref" => "#/components/schemas/user_with_root"

        run_test!

        it { expect(parsed_response_body["user"]["id"]).to eq(user.id) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized" do
        let!(:user) { instance_double(User, id: "123") }
      end

      it_behaves_like "an endpoint that returns 403 - forbidden", "l'usager·ère est lié·e à une autre organisation" do
        let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [create(:organisation)]) }
      end
    end

    patch "Mettre à jour un·e usager·ère" do
      with_authentication

      tags "User"
      produces "application/json"
      operationId "updateUser"
      description "Met à jour un·e usager·ère"

      parameter name: :user_id, in: :path, type: :integer, description: "ID de l'usager·ère", example: 123
      parameter name: "organisation_ids[]", in: :query, schema: { type: :array, items: { type: :string } }, description: "ID des organisations", example: "[123]", required: false
      parameter name: "first_name", in: :query, type: :string, description: "Prénom", example: "Johnny", required: false
      parameter name: "last_name", in: :query, type: :string, description: "Nom", example: "Silverhand", required: false
      parameter name: "birth_name", in: :query, type: :string, description: "Nom de naissance", example: "Fripouille", required: false
      parameter name: "birth_date", in: :query, type: :string, description: "Date de naissance", example: "1976-10-01", required: false
      parameter name: "email", in: :query, type: :string, description: "Email", example: "johnny@77.com", required: false
      parameter name: "phone_number", in: :query, type: :string, description: "Numéro de téléphone", example: "33600008012", required: false
      parameter name: "address", in: :query, type: :string, description: "Adresse", example: "10 rue du Havre, Paris, 75016", required: false
      parameter name: "caisse_affiliation", in: :query, type: :string, description: "Caisse d'affiliation", example: "caf", required: false
      parameter name: "affiliation_number", in: :query, type: :string, description: "Numéro d'affiliation", example: "101010", required: false
      parameter name: "family_situation", in: :query, type: :string, description: "Situation familiale", example: "single", required: false
      parameter name: "number_of_children", in: :query, type: :integer, description: "Nombre d'enfants", example: "3", required: false

      parameter name: "logement", in: :query, type: :string, enum: %w[sdf heberge en_accession_propriete proprietaire autre locataire], description: "Type de logement de l'utilisateur",
                example: "locataire", required: false
      parameter name: "notes", in: :query, type: :string, description: "Une note sur l'utilisateur", example: "Super note", required: false
      parameter name: "notify_by_sms", in: :query, type: :boolean, description: "Accepte les notifications par SMS", example: "true", required: false
      parameter name: "notify_by_email", in: :query, type: :boolean, description: "Accepte les notifications par email", example: "true", required: false
      parameter name: "responsible_id", in: :query, type: :integer, description: "ID de l'usager·ère responsable", example: 123, required: false

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      let(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation]) }
      let(:user_id) { user.id }

      response 200, "Met à jour et renvoie un·e usager·ère" do
        let(:first_name) { "Alain" }
        let(:last_name) { "Verse" }
        let(:birth_name) { "Fripouille" }
        let(:birth_date) { "1976-10-01" }
        let(:email) { "jean@jacques.fr" }
        let(:phone_number) { "33600008012" }
        let(:address) { "10 rue du Havre, Paris, 75016" }
        let(:caisse_affiliation) { "caf" }
        let(:affiliation_number) { "101010" }
        let(:family_situation) { "single" }
        let(:number_of_children) { 3 }
        let(:notes) { "Super note" }
        let(:logement) { "locataire" }
        let(:notify_by_sms) { false }
        let(:notify_by_email) { false }
        let!(:user_responsible) { create(:user) }
        let(:responsible_id) { user_responsible.id }

        schema "$ref" => "#/components/schemas/user_with_root"

        run_test!

        it { expect(user.reload.organisations).to contain_exactly(organisation) }

        it { expect(user.reload.first_name).to eq(first_name) }

        it { expect(user.reload.last_name).to eq(last_name) }

        it { expect(user.reload.birth_name).to eq(birth_name) }

        it { expect(user.reload.birth_date).to eq(Date.new(1976, 10, 1)) }

        it { expect(user.reload.email).to eq(email) }

        it { expect(user.reload.phone_number).to eq(phone_number) }

        it { expect(user.reload.address).to eq(address) }

        it { expect(user.reload.caisse_affiliation).to eq(caisse_affiliation) }

        it { expect(user.reload.affiliation_number).to eq(affiliation_number) }

        it { expect(user.reload.family_situation).to eq(family_situation) }

        it { expect(user.reload.number_of_children).to eq(number_of_children) }

        it { expect(user.reload.notes).to eq(notes) }

        it { expect(user.reload.logement).to eq(logement) }

        it { expect(user.reload.notify_by_sms).to eq(notify_by_sms) }

        it { expect(user.reload.notify_by_email).to eq(notify_by_email) }

        it { expect(user.reload.responsible).to eq(user_responsible) }
      end

      response 200, "updates a user with a minimal set of params", document: false do
        let(:first_name) { "Alain" }
        let(:last_name) { "Verse" }

        schema "$ref" => "#/components/schemas/user_with_root"

        run_test!

        it { expect(user.reload.first_name).to eq(first_name) }

        it { expect(user.reload.last_name).to eq(last_name) }
      end

      response 200, "updates a user frozen by franceconnect", document: false do
        let(:user) do
          create(:user,
                 first_name: "Jean",
                 organisations: [organisation],
                 logged_once_with_franceconnect: true)
        end

        let(:first_name) { "Alain" }
        let(:address) { "10 rue du Havre, Paris, 75016" }

        schema "$ref" => "#/components/schemas/user_with_root"

        run_test!

        it "updates non frozen attributes" do
          expect(user.reload.first_name).not_to eq(first_name)
          expect(user.address).to eq(address)
        end
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "des paramètres sont manquants ou mal formés ou impossibles", true do
        let(:"organisation_ids[]") { nil }
        let(:first_name) { nil }
        let(:last_name) { nil }
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "phone number is misformatted", false do
        let(:phone_number) { "misformatted phone number" }
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "email is taken", false do
        let!(:existing_user) { create(:user, email: "jean@jacques.fr") }
        let(:email) { existing_user.email }
      end
    end
  end

  path "/api/v1/users/{user_id}/rdv_invitation_token" do
    post "Récupérer le token d'invitation à prendre un rdv d'un usager·ère" do
      with_authentication

      tags "User", "Invitation"
      produces "application/json"
      operationId "createUserInvitation"
      description "Renvoie le token d'invitation à prendre rdv de l'usager·ère"

      parameter name: :user_id, in: :path, type: :integer, description: "ID de l'usager·ère", example: 123

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      let!(:user_id) { user.id }

      response 200, "Renvoie le token d'invitation à prendre rdv de l'usager·ère" do
        let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation], email: "jean@jacques.fr") }

        run_test!

        schema "$ref" => "#/components/schemas/invitation"

        it { expect(parsed_response_body["invitation_token"]).to eq(user.reload.rdv_invitation_token) }

        it { expect(user.reload.invited_through).to eq("external") }
      end

      response 200, "when the user doesn't have an email", document: false do
        let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", email: nil, organisations: [organisation]) }

        schema "$ref" => "#/components/schemas/invitation"

        run_test!
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized" do
        let!(:user) { instance_double(User, id: "123") }
      end

      it_behaves_like "an endpoint that returns 403 - forbidden", "l'usager·ère est lié·e à une autre organisation" do
        let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [create(:organisation)]) }
      end
    end
  end

  path "/api/v1/users" do
    get "Récupérer une liste d'usager·rès" do
      with_authentication
      with_pagination

      tags "User"
      produces "application/json"
      operationId "getUsers"
      description "Renvoie une liste paginée d'usager·ères"

      parameter name: "ids[]", in: :query, schema: { type: :array, items: { type: :string } }, description: "ID des usager·ères", example: "[123]", required: false

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Renvoie une liste paginée d'usager·ères" do
        let!(:user1) { create(:user, organisations: [organisation]) }
        let!(:user2) { create(:user, organisations: [organisation]) }
        let(:"ids[]") { [user1.id] }

        schema "$ref" => "#/components/schemas/users"

        run_test!

        it { expect(parsed_response_body["users"].pluck("id")).to contain_exactly(user1.id) }
      end

      response 200, "returns policy scoped users", document: false do
        let!(:user) { create(:user, organisations: [organisation]) }
        let!(:organisation2) { create(:organisation) }
        let!(:user2) { create(:user, organisations: [organisation2]) }
        let!(:organisation3) { create(:organisation) }
        let!(:user3) { create(:user, organisations: [organisation3]) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [organisation, organisation2]) }

        schema "$ref" => "#/components/schemas/users"

        run_test!

        it { expect(parsed_response_body["users"].pluck("id")).to contain_exactly(user.id, user2.id) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"
    end

    post "Créer un·e usager·ère" do
      with_authentication

      tags "User"
      produces "application/json"
      operationId "createUser"
      description "Crée un·e usager·ère"

      parameter name: "organisation_ids[]", in: :query, schema: { type: :array, items: { type: :string } }, description: "ID des organisations", example: "[123]"
      parameter name: "referent_agent_ids[]", in: :query, schema: { type: :array, items: { type: :string } }, description: "ID des agents référents", example: "[123]"
      parameter name: "first_name", in: :query, type: :string, description: "Prénom", example: "Johnny"
      parameter name: "last_name", in: :query, type: :string, description: "Nom", example: "Silverhand"
      parameter name: "birth_name", in: :query, type: :string, description: "Nom de naissance", example: "Fripouille", required: false
      parameter name: "birth_date", in: :query, type: :string, description: "Date de naissance", example: "1976-10-01", required: false
      parameter name: "email", in: :query, type: :string, description: "Email", example: "johnny@77.com", required: false
      parameter name: "phone_number", in: :query, type: :string, description: "Numéro de téléphone", example: "33600008012", required: false
      parameter name: "address", in: :query, type: :string, description: "Adresse", example: "10 rue du Havre, Paris, 75016", required: false
      parameter name: "caisse_affiliation", in: :query, type: :string, description: "Caisse d'affiliation", example: "caf", required: false
      parameter name: "affiliation_number", in: :query, type: :string, description: "Numéro d'affiliation", example: "101010", required: false
      parameter name: "family_situation", in: :query, type: :string, description: "Situation familiale", example: "single", required: false
      parameter name: "number_of_children", in: :query, type: :integer, description: "Nombre d'enfants", example: "3", required: false
      parameter name: "notify_by_sms", in: :query, type: :boolean, description: "Accepte les notifications par SMS", example: "true", required: false
      parameter name: "notify_by_email", in: :query, type: :boolean, description: "Accepte les notifications par email", example: "true", required: false
      parameter name: "responsible_id", in: :query, type: :integer, description: "ID de l'usager·ère responsable", example: 123, required: false

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      let(:"organisation_ids[]") { [organisation.id] }
      let(:"referent_agent_ids[]") { [agent.id] }

      response 200, "Crée et renvoie un·e usager·ère" do
        let(:first_name) { "Johnny" }
        let(:last_name) { "Silverhand" }
        let(:birth_name) { "Fripouille" }
        let(:birth_date) { "1976-10-01" }
        let(:email) { "jean@jacques.fr" }
        let(:phone_number) { "33600008012" }
        let(:address) { "10 rue du Havre, Paris, 75016" }
        let(:caisse_affiliation) { "caf" }
        let(:affiliation_number) { "101010" }
        let(:family_situation) { "single" }
        let(:notes) { "Quelques remarques" }
        let(:logement) { :locataire }
        let(:number_of_children) { 3 }
        let(:notify_by_sms) { false }
        let(:notify_by_email) { false }
        let!(:user_responsible) { create(:user) }
        let(:responsible_id) { user_responsible.id }

        let!(:user_count_before) { User.count }
        let(:created_user) { User.find(parsed_response_body["user"]["id"]) }

        schema "$ref" => "#/components/schemas/user_with_root"

        run_test!

        it "creates user with expected attributes" do
          expect(User.count).to eq(user_count_before + 1)
          expect(created_user.organisations).to contain_exactly(organisation)
          expect(created_user.referent_agents).to contain_exactly(agent)
          expect(created_user).to have_attributes(
            first_name:,
            last_name:,
            birth_name:,
            birth_date: Date.new(1976, 10, 1),
            email:,
            phone_number:,
            address:,
            caisse_affiliation:,
            affiliation_number:,
            family_situation:,
            number_of_children:,
            notify_by_sms:,
            notify_by_email:,
            responsible: user_responsible
          )
        end
      end

      response 200, "creates a user with a minimal set of params", document: false do
        let(:first_name) { "Johnny" }
        let(:last_name) { "Silverhand" }

        let!(:user_count_before) { User.count }
        let(:created_user) { User.find(parsed_response_body["user"]["id"]) }

        schema "$ref" => "#/components/schemas/user_with_root"

        run_test!

        it { expect(User.count).to eq(user_count_before + 1) }

        it { expect(created_user.organisations).to contain_exactly(organisation) }

        it { expect(created_user.first_name).to eq(first_name) }

        it { expect(created_user.last_name).to eq(last_name) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized" do
        let(:"organisation_ids[]") { [organisation.id] }
        let(:first_name) { "Johnny" }
        let(:last_name) { "Silverhand" }
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "des paramètres sont manquants, mal formés ou impossibles", true do
        let(:first_name) { nil }
        let(:last_name) { nil }
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "phone number is misformatted", false do
        let(:first_name) { "Johnny" }
        let(:last_name) { "Silverhand" }
        let(:phone_number) { "misformatted phone number" }
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "email is taken", false do
        let(:first_name) { "Johnny" }
        let(:last_name) { "Silverhand" }

        let!(:existing_user) { create(:user, email: "jean@jacques.fr") }
        let(:email) { existing_user.email }
      end
    end
  end

  path "/api/v1/organisations/{organisation_id}/users" do
    get "Récupérer une liste d'usager·rès d'une organisation" do
      with_authentication
      with_pagination

      tags "User"
      produces "application/json"
      operationId "getUsersFromOrganisation"
      description "Renvoie une liste paginée d'usager·ères d'une organisation"

      parameter name: :organisation_id, in: :path, type: :integer, description: "ID de l'organisation", example: 123

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      let(:organisation_id) { organisation.id }

      response 200, "Renvoie une liste paginée d'usager·ères d'une organisation" do
        let!(:user1) { create(:user, organisations: [organisation]) }
        let!(:organisation2) { create(:organisation) }
        let!(:user2) { create(:user, organisations: [organisation2]) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [organisation, organisation2]) }

        schema "$ref" => "#/components/schemas/users"

        run_test!

        it { expect(parsed_response_body["users"].pluck("id")).to contain_exactly(user1.id) }
      end

      response 200, "does not return the users list when the agent does not belong to the organisation", document: false do
        let!(:other_orga) { create(:organisation) }
        let!(:user) { create(:user, organisations: [other_orga]) }

        schema "$ref" => "#/components/schemas/users"

        run_test!

        it { expect(parsed_response_body["users"]).to eq([]) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"
    end
  end

  path "/api/v1/organisations/{organisation_id}/users/{user_id}" do
    get "Récupérer un·e usager·ère d'une organisation" do
      with_authentication

      tags "User"
      produces "application/json"
      operationId "getUserFromOrganisation"
      description "Renvoie un·e usager·ère"

      parameter name: :user_id, in: :path, type: :integer, description: "ID de l'usager·ère", example: 123
      parameter name: :organisation_id, in: :path, type: :integer, description: "ID de l'organisation", example: 456

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      let(:organisation_id) { organisation.id }
      let(:user_id) { user.id }

      response 200, "Renvoie l'usager·ère d'une organisation" do
        let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation], email: "jean@jacques.fr") }

        schema "$ref" => "#/components/schemas/user_with_root"

        run_test!

        it { expect(parsed_response_body[:user][:id]).to eq(user.id) }
      end

      response 200, "authorized user ID also belongs to other organisation", document: false do
        let!(:unauthorized_orga) { create(:organisation) }
        let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation, unauthorized_orga]) }

        schema "$ref" => "#/components/schemas/user_with_root"

        run_test!

        it { expect(parsed_response_body["user"]["id"]).to eq(user.id) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized" do
        let!(:user) { instance_double(User, id: "123") }
      end

      it_behaves_like "an endpoint that returns 403 - forbidden", "quand l'agent ne fait pas partie de l'organisation" do
        let!(:agent) { create(:agent, basic_role_in_organisations: [create(:organisation)]) }
        let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation], email: "jean@jacques.fr") }
      end

      it_behaves_like "an endpoint that returns 404 - not found", "l'usager·ère n'est pas lié·e à l'organisation" do
        let!(:another_org) { create(:organisation) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [another_org]) }
        let!(:user) { create(:user, organisations: [another_org]) }
      end
    end
  end
end
