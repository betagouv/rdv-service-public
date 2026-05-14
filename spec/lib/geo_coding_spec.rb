RSpec.describe GeoCoding do
  describe "#find_geo_coordinates" do
    before do
      stub_request(
        :get,
        "https://data.geopf.fr/geocodage/search/?q=03%20Rue%20Lambert,%20Paris,%2075018"
      ).to_return(status: 200, body: file_fixture("geocode_result.json").read, headers: {})
    end

    it "returns the coordinates" do
      expect(described_class.new.find_geo_coordinates("03 Rue Lambert, Paris, 75018")).to eq([2.372095, 48.88393])
    end
  end

  describe "#get_geolocation_results" do
    let(:geo_coding) { described_class.new }
    let(:address) { "20 avenue de Ségur, Paris, 75007" }
    let(:departement_number) { "75" }

    context "avec un identifiant de rue contenant trois parties" do
      before do
        stub_request(
          :get,
          "https://data.geopf.fr/geocodage/search/?q=20%20avenue%20de%20S%C3%A9gur,%20Paris,%2075007"
        ).to_return(
          status: 200,
          body: {
            type: "FeatureCollection",
            features: [
              {
                type: "Feature",
                geometry: { type: "Point", coordinates: [2.372095, 48.88393] },
                properties: {
                  id: "75056_qehkqd_00053",
                  citycode: "75056",
                  context: "75, Paris, Île-de-France",
                },
              },
            ],
          }.to_json,
          headers: {}
        )
      end

      it "supprime tout ce qui se trouve après le deuxième underscore" do
        result = geo_coding.get_geolocation_results(address, departement_number)

        expect(result).to include(
          city_code: "75056",
          street_ban_id: "75056_qehkqd"
        )
      end
    end

    context "avec un identifiant de rue contenant deux parties" do
      before do
        stub_request(
          :get,
          "https://data.geopf.fr/geocodage/search/?q=20%20avenue%20de%20S%C3%A9gur,%20Paris,%2075007"
        ).to_return(
          status: 200,
          body: {
            type: "FeatureCollection",
            features: [
              {
                type: "Feature",
                geometry: { type: "Point", coordinates: [2.372095, 48.88393] },
                properties: {
                  id: "75056_1234",
                  citycode: "75056",
                  context: "75, Paris, Île-de-France",
                },
              },
            ],
          }.to_json,
          headers: {}
        )
      end

      it "conserve l'identifiant tel quel" do
        result = geo_coding.get_geolocation_results(address, departement_number)

        expect(result).to include(
          city_code: "75056",
          street_ban_id: "75056_1234"
        )
      end
    end

    context "quand aucun résultat n'est trouvé" do
      before do
        stub_request(
          :get,
          "https://data.geopf.fr/geocodage/search/?q=20%20avenue%20de%20S%C3%A9gur,%20Paris,%2075007"
        ).to_return(
          status: 200,
          body: {
            type: "FeatureCollection",
            features: [],
          }.to_json,
          headers: {}
        )
      end

      it "retourne nil" do
        result = geo_coding.get_geolocation_results(address, departement_number)

        expect(result).to be_nil
      end
    end

    context "quand l'adresse commence par des caractères non-alphanumériques" do
      let(:address) { ". LA BEGUDE 84750 SAINT-MARTIN-DE-CASTILLON" }
      let(:departement_number) { "84" }
      let(:cleaned_request_url) do
        "https://data.geopf.fr/geocodage/search/?q=LA%20BEGUDE%2084750%20SAINT-MARTIN-DE-CASTILLON"
      end

      before do
        stub_request(:get, cleaned_request_url).to_return(
          status: 200,
          body: {
            type: "FeatureCollection",
            features: [
              {
                type: "Feature",
                geometry: { type: "Point", coordinates: [5.51, 43.85] },
                properties: {
                  id: "84112_i530ru",
                  citycode: "84112",
                  context: "84, Vaucluse, Provence-Alpes-Côte d'Azur",
                },
              },
            ],
          }.to_json,
          headers: {}
        )
      end

      it "envoie l'adresse nettoyée à l'API IGN" do
        geo_coding.get_geolocation_results(address, departement_number)

        expect(WebMock).to have_requested(:get, cleaned_request_url)
      end
    end

    context "quand l'API IGN retourne un status non-success" do
      let(:request_url) do
        "https://data.geopf.fr/geocodage/search/?q=20%20avenue%20de%20S%C3%A9gur,%20Paris,%2075007"
      end

      before do
        stub_request(:get, request_url).to_return(status: 400, body: "")
        allow(Sentry).to receive(:capture_message)
      end

      it "retourne nil et signale l'erreur à Sentry" do
        expect(Sentry).to receive(:capture_message)

        expect(geo_coding.get_geolocation_results(address, departement_number)).to be_nil
      end

      it "ne met pas la réponse en cache pour permettre une nouvelle tentative" do
        2.times { geo_coding.get_geolocation_results(address, departement_number) }

        expect(WebMock).to have_requested(:get, request_url).twice
      end
    end

    context "quand Faraday lève une exception" do
      before do
        stub_request(
          :get,
          "https://data.geopf.fr/geocodage/search/?q=20%20avenue%20de%20S%C3%A9gur,%20Paris,%2075007"
        ).to_raise(Faraday::Error)
      end

      it "retourne nil et signale l'exception à Sentry" do
        expect(Sentry).to receive(:capture_exception)

        expect(geo_coding.get_geolocation_results(address, departement_number)).to be_nil
      end
    end

    context "quand l'appel réussit" do
      let(:request_url) do
        "https://data.geopf.fr/geocodage/search/?q=20%20avenue%20de%20S%C3%A9gur,%20Paris,%2075007"
      end

      before do
        stub_request(:get, request_url).to_return(
          status: 200,
          body: {
            type: "FeatureCollection",
            features: [
              {
                type: "Feature",
                properties: { id: "75056_1234", citycode: "75056", context: "75, Paris, Île-de-France" },
              },
            ],
          }.to_json
        )
      end

      it "met le résultat en cache pour ne pas refaire l'appel une seconde fois" do
        geo_coding.get_geolocation_results(address, departement_number)
        geo_coding.get_geolocation_results(address, departement_number)

        expect(WebMock).to have_requested(:get, request_url).once
      end
    end
  end
end
