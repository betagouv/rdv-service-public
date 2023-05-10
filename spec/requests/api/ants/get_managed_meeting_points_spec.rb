# frozen_string_literal: true

require "swagger_helper"

describe "ANTS API", swagger_doc: "ants/api.json" do
  around do |example|
    previous_auth_token = ENV["ANTS_API_AUTH_TOKEN"]

    ENV["ANTS_API_AUTH_TOKEN"] = "fake_ants_api_auth_token"

    example.run

    ENV["ANTS_API_AUTH_TOKEN"] = previous_auth_token
  end

  let(:parsed_response_body) { JSON.parse(response.body) }

  path "/api/ants/getManagedMeetingPoints" do
    get "Lister les municipalités pour lesquelles nous permettons la prise de RDV" do
      produces "application/json"
      operationId "getManagedMeetingPoints"

      context "sans le header d'authentification" do
        response 401, "Renvoie 'unauthorized' quand l'authentification est impossible" do
          run_test!
        end
      end

      context "avec le mauvais header d'autentification" do
      end

      response 200, "Renvoie la liste des lieux correspondant aux municipalités" do
        run_test!

        specify do
          expect(parsed_response_body).to eq([])
        end
      end
    end
  end
end
