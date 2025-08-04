RSpec.describe CronJob::IGNHealthCheckJob, type: :job do
  subject(:perform_now) { described_class.perform_now }

  before do
    stub_request(:get, "https://data.geopf.fr/geocodage/search?q=1+place+de+la+republique+75011+paris&limit=1")
      .to_return(status: 200, body: "", headers: {})
  end

  it "ne déclenche pas de Sentry" do
    expect(Faraday).to receive(:get).with("https://data.geopf.fr/geocodage/search?q=1+place+de+la+republique+75011+paris&limit=1")
    expect(Sentry).not_to receive(:capture_message)
    perform_now
  end

  context "quand l’API de l’IGN renvoie une erreur" do
    before do
      stub_request(:get, "https://data.geopf.fr/geocodage/search?q=1+place+de+la+republique+75011+paris&limit=1")
        .to_return(status: 500, body: "", headers: {})
    end

    it "incrémente le compteur Redis" do
      perform_now
      expect(Redis.with_connection { |redis| redis.get("ign_api_health_check_failures").to_i }).to eq(1)
    end

    it "fais expirer le compteur Redis après 2 minutes" do
      perform_now
      expect(Redis.with_connection { |redis| redis.ttl("ign_api_health_check_failures") }).to eq(120)
    end

    it "ne déclenche pas de message Sentry" do
      expect(Sentry).not_to receive(:capture_message)
      perform_now
    end
  end

  context "quand l’API de l’IGN renvoie une erreur 3 fois" do
    before do
      stub_request(:get, "https://data.geopf.fr/geocodage/search?q=1+place+de+la+republique+75011+paris&limit=1")
        .to_return(status: 500, body: "", headers: {})
    end

    it "déclenche un message Sentry après 3 échecs consécutifs" do
      expect(Sentry).to receive(:capture_message).with("L'API adresse de l'IGN est inaccessible (HTTP status: 500). Vérifier l’état du service ici : https://status.uptrends.com/aa35b49e519e4f90866dc6bfc0a797a9/7ec26cae-995d-4974-926a-9130b14f77be?SelectedPeriod=Last30Days")
      3.times { described_class.perform_now }
      expect(Redis.with_connection { |redis| redis.get("ign_api_health_check_failures").to_i }).to eq(3)
    end
  end

  context "quand l’API de l’IGN timeoute" do
    before do
      stub_request(:get, "https://data.geopf.fr/geocodage/search?q=1+place+de+la+republique+75011+paris&limit=1")
        .to_raise(Faraday::TimeoutError)
    end

    it "incrémente le compteur Redis" do
      perform_now
      expect(Redis.with_connection { |redis| redis.get("ign_api_health_check_failures").to_i }).to eq(1)
    end
  end
end
