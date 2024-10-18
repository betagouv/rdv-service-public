require "swagger_helper"

RSpec.describe "Visioplainte API", swagger_doc: "visioplainte/api.json" do # rubocop:disable RSpec/EmptyExampleGroup
  before do
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  before do
    create(:plage_ouverture, :weekdays, agent: agent, first_day: Date.new(2024, 8, 19), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12))
  end

  let(:agent) do
    Agent.joins(:services).where(services: { name: "Gendarmerie Nationale" }).last
  end

  path "/api/visioplainte/plages_ouverture" do
    get "Ces plages d'ouvertures sont les horaires sur lesquels un guichet est ouvert, et permettent de savoir à quels guichets affecter des agents.\
        Cet enpoint permet d'obtenir la liste des occurrences pour une période donnée (une plage d'ouverture récurrente ayant plusieurs occurrences).\
        Cet endpoint ne prend pas encore en compte les absences." do
      with_visioplainte_authentication
      tags "Plages d'ouverture"
      response 200, "Renvoie la liste des plages d'ouverture" do
        run_test!
        parameter name: "date_debut", in: :query, type: :string, description: "date au format iso8601 (YYYY-MM-DD), premier jour de la liste qu’on renverra",
                  example: "2024-12-22", required: true
        parameter name: "date_fin", in: :query, type: :string, description: "date au format iso8601 (YYYY-MM-DD), dernier jour de la liste qu’on renverra (inclus dans les résultats)",
                  example: "2024-12-28", required: true
        parameter name: "guichet_ids[]", in: :query, type: :array,
                  description: "Une liste d'ids des guichets sur lesquels on veut filtrer les plages d'ouverture", required: false

        let(:date_debut) { "2024-08-19" }
        let(:date_fin) { "2024-08-25" }
      end
    end
  end
end
