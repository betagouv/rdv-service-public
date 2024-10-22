RSpec.describe "Visioplainte Guichets" do
  before do
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  let!(:other_intervenant) do
    create(:agent, :intervenant, services: [service_gendarmerie], organisations: [create(:organisation)])
  end

  let(:service_gendarmerie) do
    Service.find_by(name: "Gendarmerie Nationale")
  end

  include_context "Visioplainte Auth"

  it "returns the list of guichets for visioplainte but not intervenants in other places" do
    get "/api/visioplainte/guichets", headers: auth_header
    parsed_response_body = response.parsed_body.deep_symbolize_keys

    expect(parsed_response_body[:guichets]).to contain_exactly(
      {
        id: anything, name: "GUICHET 1",
      },
      {
        id: anything, name: "GUICHET 2",
      }
    )
  end
end
