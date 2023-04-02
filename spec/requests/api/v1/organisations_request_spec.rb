# frozen_string_literal: true

require "swagger_helper"

describe "Organisations API", swagger_doc: "v1/api.json" do
  with_examples

  path "/api/v1/organisations" do
    get "Lister les organisations" do
      with_authentication
      with_pagination

      tags "Organisation"
      produces "application/json"
      operationId "getOrganisations"
      description "Renvoie toutes les organisations accessibles à l'agent·e authentifié·e, de manière paginée"

      parameter name: "departement_number", in: :query, type: :string, description: "Le numéro ou code de département du territoire concerné", example: "26", required: false
      parameter name: "city_code", in: :query, type: :string, description: "Le code INSEE de la localité", example: "26323", required: false

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Retourne des Organisations" do
        let!(:organisations) { create_list(:organisation, 5) }
        let!(:agent) { create(:agent, basic_role_in_organisations: Organisation.all) }
        let!(:other_organisation) { create(:organisation) }
        let!(:other_agent) { create(:agent, basic_role_in_organisations: [other_organisation]) }

        schema "$ref" => "#/components/schemas/organisations"

        run_test!

        it { expect(response).to be_paginated(current_page: 1, next_page: nil, prev_page: nil, total_count: 5, total_pages: 1) }

        it { expect(parsed_response_body[:organisations]).to match(OrganisationBlueprint.render_as_hash(organisations)) }
      end

      response 200, "Retourne des Organisations, filtrées par secteur géographique", document: false do
        let!(:unmatching) { create(:organisation) }
        let!(:matching) { create(:organisation) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [unmatching, matching]) }
        let(:departement_number) { "26" }
        let(:city_code) { "26323" }

        before do
          allow(Users::GeoSearch).to receive(:new)
            .with(departement: departement_number, city_code: city_code, street_ban_id: nil)
            .and_return(instance_double(Users::GeoSearch, most_relevant_organisations: Organisation.where(id: matching.id)))
        end

        run_test!

        it { expect(parsed_response_body[:organisations]).to match([OrganisationBlueprint.render_as_hash(matching)]) }
      end

      response 200, "when there is no organisation", document: false do
        let(:agent) { create(:agent) }

        run_test!

        it { expect(parsed_response_body[:organisations]).to eq([]) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized" do
        let(:agent) { create(:agent) }
      end
    end
  end

  path "api/v1/organisations/{organisation_id}" do
    get "Récupérer une organisation" do
      with_authentication
      with_pagination

      tags "Organisation"
      produces "application/json"
      operationId "getOrganisation"
      description "Renvoie une organisation"

      parameter name: :organisation_id, in: :path, type: :integer, description: "ID de l'organisation", example: 123

      let!(:organisation) { create(:organisation) }
      let!(:agent) { create(:agent, basic_role_in_organisations: Organisation.all) }
      let(:organisation_id) { organisation.id }

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Retourne une Organisation" do
        schema "$ref" => "#/components/schemas/organisation_with_root"

        run_test!

        it { expect(parsed_response_body[:organisation]).to match(OrganisationBlueprint.render_as_hash(organisation)) }
      end
    end
  end

  path "api/v1/organisations/{organisation_id}" do
    patch "Mettre à jour une organisation" do
      with_authentication

      tags "Organisation"
      produces "application/json"
      operationId "updateOrganisation"
      description "Met à jour une organisation"

      parameter name: :organisation_id, in: :path, type: :integer, description: "ID de l'organisation", example: 123
      parameter name: "name", in: :query, type: :string, description: "Nom", example: "Centre d'action sociale", required: false
      parameter name: "email", in: :query, type: :string, description: "Email", example: "cas@77.com", required: false
      parameter name: "phone_number", in: :query, type: :string, description: "Numéro de téléphone", example: "33100008012", required: false

      let!(:organisation) { create(:organisation) }
      let(:organisation_id) { organisation.id }
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

      let(:auth_headers) { api_auth_headers_for_agent(agent) }
      let(:"access-token") { auth_headers["access-token"].to_s }
      let(:uid) { auth_headers["uid"].to_s }
      let(:client) { auth_headers["client"].to_s }

      response 200, "Met à jour et renvoie un·e usager·ère" do
        let(:name) { "Pole parcours" }
        let(:email) { "pole@parcours.fr" }
        let(:phone_number) { "33100008012" }

        schema "$ref" => "#/components/schemas/organisation_with_root"

        run_test!

        it { expect(organisation.reload.name).to eq(name) }

        it { expect(organisation.reload.email).to eq(email) }

        it { expect(organisation.reload.phone_number).to eq(phone_number) }
      end

      response 200, "updates an organisation with a minimal set of params", document: false do
        let(:email) { "pole@parcours.fr" }

        schema "$ref" => "#/components/schemas/organisation_with_root"

        run_test!

        it { expect(organisation.reload.email).to eq(email) }
      end

      it_behaves_like "an endpoint that returns 401 - unauthorized"

      it_behaves_like "an endpoint that returns 403 - forbidden" do
        let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      end

      it_behaves_like "an endpoint that returns 403 - forbidden" do
        let!(:other_organisation) { create(:organisation) }
        let!(:agent) { create(:agent, admin_role_in_organisations: [other_organisation]) }
      end

      it_behaves_like "an endpoint that returns 422 - unprocessable_entity", "phone number is misformatted", false do
        let(:phone_number) { "misformatted phone number" }
      end
    end
  end
end
