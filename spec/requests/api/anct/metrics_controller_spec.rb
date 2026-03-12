RSpec.describe "/api/anct/metrics" do
  stub_env_with(CARTO_ANCT_SHARED_SECRET: "t0p_s3cr3t!", CARTO_ANCT_ENABLED: "true")

  let(:bearer) { "t0p_s3cr3t!" }
  let(:auth_headers) { { "Authorization" => "Bearer #{bearer}" } }

  let(:valid_cached_metrics) do
    [
      { insee: "01001", metrics: { tu: 244 } },
      { insee: "01006", metrics: { tu: 133 } },
      { metrics: { tu: 10 }, siret: "12345678901234" },
      { metrics: { tu: 32 }, siret: "13002526500013" },
    ]
  end

  it "works when cached is warmed up" do
    allow(CartoANCT).to receive(:cached_metrics).and_return(valid_cached_metrics)
    get "/api/anct/metrics", headers: auth_headers
    expect(response.parsed_body["results"].size).to eq(4)
  end

  it "allows for offset-based pagination" do
    # On simule 1400 résultats
    allow(CartoANCT).to receive(:cached_metrics).and_return(1400.times.map { |i| { insee: i.to_s.rjust(5, "0"), metrics: { tu: i * 2 } } })

    get "/api/anct/metrics", headers: auth_headers, params: { limit: 800 }
    expect(response.parsed_body["results"].size).to eq(800)

    get "/api/anct/metrics", headers: auth_headers, params: { offset: 0 }
    expect(response.parsed_body["results"].first).to eq({ "insee" => "00000", "metrics" => { "tu" => 0 } })

    get "/api/anct/metrics", headers: auth_headers, params: { offset: 1230 }
    expect(response.parsed_body["results"].first).to eq({ "insee" => "01230", "metrics" => { "tu" => 2460 } })
  end

  it "returns a 500 with JSON body on error" do
    allow(CartoANCT).to receive(:cached_metrics).and_raise("boom")
    get "/api/anct/metrics", headers: auth_headers
    expect(response).to have_http_status(:internal_server_error)
    expect(response.body).to eq("{\"error\":\"Erreur interne du serveur\"}")
  end

  it 'returns a 404 when ENV["CARTO_ANCT_ENABLED"] is not set' do
    with_modified_env(CARTO_ANCT_ENABLED: nil) do
      get "/api/anct/metrics", headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "authentication" do
    before do
      allow(CartoANCT).to receive(:cached_metrics).and_return(valid_cached_metrics)
    end

    context "when providing the correct shared secret" do
      it "return a 200 with the data" do
        get "/api/anct/metrics", headers: auth_headers
        expect(response).to have_http_status(:success)
        expect(response.parsed_body["results"].size).to eq(4)
      end
    end

    context "when providing an incorrect shared secret" do
      it "return a 401 with no body" do
        get "/api/anct/metrics", headers: { "Authorization" => "Bearer coucou" }
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to eq("{\"error\":\"Authentification invalide\"}")
      end
    end

    context "when providing no shared secret headers" do
      it "return a 401 with no body" do
        get "/api/anct/metrics"
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to eq("{\"error\":\"Authentification invalide\"}")
      end
    end
  end
end
