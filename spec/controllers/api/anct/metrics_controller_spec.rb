RSpec.describe Api::Anct::MetricsController do
  it "works" do
    get :index
    expect(response.parsed_body["results"].size).to eq(18595)

    get :index, params: { limit: 1000 }
    expect(response.parsed_body["results"].size).to eq(1000)

    get :index, params: { offset: 0 }
    expect(response.parsed_body["results"].first).to eq({ "insee" => "01001", "metrics" => { "tu" => 4 } })
    get :index, params: { offset: 1 }
    expect(response.parsed_body["results"].first).to eq({ "insee" => "01002", "metrics" => { "tu" => 1 } })
  end
end
