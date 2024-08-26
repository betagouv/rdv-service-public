RSpec.shared_context "Visioplainte" do
  before do
    travel_to Time.zone.local(2024, 8, 18, 14, 0, 0)
    load Rails.root.join("db/seeds/visioplainte.rb")
  end

  stub_env_with(VISIOPLAINTE_API_KEY: "visioplainte-api-test-key-123456")

  let(:auth_header) do
    { "X-VISIOPLAINTE-API-KEY": "visioplainte-api-test-key-123456" }
  end
end
