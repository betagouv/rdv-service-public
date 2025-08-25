RSpec.describe "Api pour Justice.fr" do
  it "renvoie une liste des lieux de justice" do
    get "/api/justice/lieux"
    parsed_response = JSON.parse(response.body)
    expect(parsed_response.symbolize_keys).to eq({ lieux: [] })
  end
end
