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

    it "déclenche un message Sentry" do
      expect(Sentry).to receive(:capture_message).with(
        "L'API adresse de l'IGN est inaccessible (HTTP status: 500). Vérifier l’état du service ici : https://status.uptrends.com/aa35b49e519e4f90866dc6bfc0a797a9/7ec26cae-995d-4974-926a-9130b14f77be?SelectedPeriod=Last30Days"
      )
      perform_now
    end
  end
end
