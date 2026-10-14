RSpec.describe MetabaseApi do
  describe ".sql_query" do
    let(:url) { "#{described_class::HOST_URL}/api/dataset/json" }

    stub_env_with(
      METABASE_API_KEY: "fake-api-key",
      METABASE_BASIC_AUTH_USER: "fake-user",
      METABASE_BASIC_AUTH_PASSWORD: "fake-password"
    )

    it "envoie la requête SQL avec les bons headers et l'authentification basic, et parse le JSON" do
      stub = stub_request(:post, url)
        .with(
          basic_auth: %w[fake-user fake-password],
          headers: { "X-Api-Key" => "fake-api-key", "Content-Type" => "application/json", "Accept" => "application/json" }
        ) { |req| JSON.parse(req.body) == { "query" => { "database" => 2, "native" => { "query" => "SELECT 1" }, "type" => "native" } } }
        .to_return(status: 200, body: [{ c: 1 }].to_json)

      expect(described_class.sql_query("SELECT 1")).to eq([{ "c" => 1 }])
      expect(stub).to have_been_requested
    end

    it "renvoie le JSON brut avec raw_json: true" do
      stub_request(:post, url).to_return(status: 200, body: '[{"c":1}]')

      expect(described_class.sql_query("SELECT 1", raw_json: true)).to eq('[{"c":1}]')
    end

    it "lève une erreur si le statut n'est pas 200" do
      stub_request(:post, url).to_return(status: 500, body: "boom")

      expect { described_class.sql_query("SELECT 1") }
        .to raise_error(described_class::Error, "Statut 500 retourné par l’API metabase dataset/json")
    end

    it "lève une erreur en cas de timeout" do
      stub_request(:post, url).to_timeout

      expect { described_class.sql_query("SELECT 1") }.to raise_error(StandardError)
    end
  end
end
