require "swagger_helper"

RSpec.describe "Visioplainte API", swagger_doc: "visioplainte/api.json" do # rubocop:disable RSpec/EmptyExampleGroup
  before do
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  def self.guichet_response_schema
    {
      type: :object,
      properties: {
        id: { type: :integer },
        name: { type: :string },
      },
      required: %i[id name],
    }
  end

  path "/api/visioplainte/guichets" do
    get "Les guichets représentent des postes physiques. Il est possible d'ouvrir une plage d'ouverture pour un guichet. Un rdv est associé à un guichet" do
      with_visioplainte_authentication

      tags "Guichets"
      response 200, "Renvoie la liste des guichets" do
        run_test!
      end
    end
  end
end
