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

      before do
        stub_request(
          :get,
          "https://data.geopf.fr/geocodage/search/?q=LA%20BEGUDE%2084750%20SAINT-MARTIN-DE-CASTILLON"
        ).to_return(
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

      it "nettoie l'adresse avant d'appeler l'API IGN et retourne le résultat" do
        result = geo_coding.get_geolocation_results(address, departement_number)

        expect(result).to include(city_code: "84112")
      end
    end
  end
end
