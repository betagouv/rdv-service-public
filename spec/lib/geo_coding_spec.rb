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

    let(:stub_body) do
      {
        type: "FeatureCollection",
        features: [
          {
            type: "Feature",
            geometry: { type: "Point", coordinates: [2.308628, 48.854] },
            properties: {
              id: "69123_4567_00020",
              citycode: "69123",
              postcode: "69007",
              city: "Lyon",
              context: "69, Rhône, Auvergne-Rhône-Alpes",
            },
          },
          {
            type: "Feature",
            geometry: { type: "Point", coordinates: [2.308628, 48.854] },
            properties: {
              id: "75107_8909_00020",
              citycode: "75107",
              postcode: "75007",
              city: "Paris",
              context: "75, Paris, Île-de-France",
            },
          },
        ],
      }.to_json
    end

    before do
      stub_request(
        :get,
        "https://data.geopf.fr/geocodage/search/?q=20%20avenue%20de%20S%C3%A9gur,%20Paris,%2075007"
      ).to_return(status: 200, body: stub_body, headers: {})
    end

    context "avec un departement_number" do
      it "retourne le résultat correspondant au département" do
        result = geo_coding.get_geolocation_results(address, "75")

        expect(result).to include(
          city_code: "75107",
          post_code: "75007",
          city_name: "Paris",
          street_ban_id: "75107_8909"
        )
      end
    end

    context "sans departement_number" do
      it "retourne le premier résultat" do
        result = geo_coding.get_geolocation_results(address)

        expect(result).to include(
          city_code: "69123",
          post_code: "69007",
          city_name: "Lyon",
          street_ban_id: "69123_4567"
        )
      end
    end

    context "avec un identifiant de rue contenant deux parties" do
      let(:stub_body) do
        {
          type: "FeatureCollection",
          features: [
            {
              type: "Feature",
              geometry: { type: "Point", coordinates: [2.372095, 48.88393] },
              properties: {
                id: "75056_1234",
                citycode: "75056",
                postcode: "75007",
                city: "Paris",
                context: "75, Paris, Île-de-France",
              },
            },
          ],
        }.to_json
      end

      it "conserve l'identifiant tel quel" do
        result = geo_coding.get_geolocation_results(address, "75")

        expect(result).to include(
          city_code: "75056",
          street_ban_id: "75056_1234"
        )
      end
    end

    context "quand aucun résultat n'est trouvé" do
      let(:stub_body) { { type: "FeatureCollection", features: [] }.to_json }

      it "retourne nil" do
        expect(geo_coding.get_geolocation_results(address, "75")).to be_nil
      end
    end
  end
end
