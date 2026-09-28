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

    context "quand l'API renvoie une erreur (ex: page HTML de maintenance)" do
      before do
        stub_request(
          :get,
          "https://data.geopf.fr/geocodage/search/?q=20%20avenue%20de%20S%C3%A9gur,%20Paris,%2075007"
        ).to_return(status: 503, body: "<html><body>Service indisponible</body></html>", headers: {})
      end

      it "retourne nil sans lever d'exception" do
        result = geo_coding.get_geolocation_results(address, departement_number)

        expect(result).to be_nil
      end

      it "ne met pas la réponse en échec en cache" do
        geo_coding.get_geolocation_results(address, departement_number)

        expect(Rails.cache.read("api-adresse:#{address}")).to be_nil
      end
    end
  end

  describe "#search_addresses" do
    let(:query) { "plaisance garenne" }

    it "renvoie les adresses trouvées avec les paramètres attendus par la recherche de RDV" do
      commune = ban_feature(
        name: "La Garenne-Colombes", city: "La Garenne-Colombes", postcode: "92250", citycode: "92035",
        id: "92035", context: "92, Hauts-de-Seine, Île-de-France", type: "municipality"
      )
      stub_geocoding_search(query, ban_feature_79_rue_de_plaisance(score: 0.9), ban_feature_rue_de_plaisance_nogent, commune)

      expected_results = [
        {
          label: "79 Rue de Plaisance, La Garenne-Colombes, 92250", score: 0.9, departement: "92",
          city_code: "92035", street_ban_id: "92035_7180", latitude: 48.9, longitude: 2.25,
        },
        {
          label: "Rue de Plaisance, Nogent-sur-Marne, 94130", score: 0.6, departement: "94",
          city_code: "94052", street_ban_id: "94052_0750", latitude: 48.9, longitude: 2.25,
        },
        {
          label: "La Garenne-Colombes, 92250", score: 0.95, departement: "92",
          city_code: "92035", street_ban_id: nil, latitude: 48.9, longitude: 2.25,
        },
      ]
      expect(described_class.new.search_addresses(query).map(&:to_h)).to eq(expected_results)
    end

    it "renvoie un tableau vide quand aucune adresse ne correspond" do
      stub_geocoding_search(query)

      expect(described_class.new.search_addresses(query)).to eq([])
    end

    it "renvoie nil quand l'API est indisponible" do
      stub_request(:get, "https://data.geopf.fr/geocodage/search/").with(query: { q: query, limit: 5 }).to_timeout

      expect(described_class.new.search_addresses(query)).to be_nil
    end
  end

  describe ".auto_selectable_result" do
    def result(score)
      GeoCoding::AddressResult.new(label: "adresse #{score}", score:, departement: "92", city_code: nil, street_ban_id: nil, latitude: nil, longitude: nil)
    end

    it "renvoie le seul résultat ayant un score élevé" do
      expect(described_class.auto_selectable_result([result(0.97), result(0.65), result(0.6)])).to eq(result(0.97))
    end

    it "ne renvoie rien quand plusieurs résultats ont un score élevé" do
      expect(described_class.auto_selectable_result([result(0.97), result(0.9)])).to be_nil
    end

    it "ne renvoie rien quand aucun résultat n'a un score élevé" do
      expect(described_class.auto_selectable_result([result(0.7)])).to be_nil
      expect(described_class.auto_selectable_result(nil)).to be_nil
    end
  end
end
