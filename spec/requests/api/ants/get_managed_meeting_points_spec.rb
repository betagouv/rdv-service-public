# frozen_string_literal: true

require "swagger_helper"

describe "ANTS API", swagger_doc: "ants/api.json" do
  let(:parsed_response_body) { JSON.parse(response.body) }

  path "/api/ants/getManagedMeetingPoints" do
    get "Lister les municipalités pour lesquelles nous permettons la prise de RDV" do
      produces "application/json"
      operationId "getManagedMeetingPoints"

      response 200, "Renvoie la liste des lieux correspondant aux municipalités" do
        run_test!

        specify do
          expect(parsed_response_body).to eq([])
        end
      end
    end
  end
end
