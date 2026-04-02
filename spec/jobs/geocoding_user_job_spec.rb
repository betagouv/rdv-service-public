RSpec.describe GeocodingUserJob do
  describe "#perform" do
    let(:user) { create(:user, address: "20 avenue de Ségur, Paris, 75007") }

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
        }.to_json,
        headers: {}
      )
    end

    it "met à jour les informations de geocoding de l'usager" do
      described_class.new.perform(user.id)

      user.reload
      expect(user.city_code).to eq("75107")
      expect(user.post_code).to eq("75007")
      expect(user.city_name).to eq("Paris")
    end

    context "quand l'usager n'a pas d'adresse" do
      let(:user) { create(:user, address: nil) }

      it "ne fait rien" do
        described_class.new.perform(user.id)

        user.reload
        expect(user.city_code).to be_nil
      end
    end

    context "quand l'API ne retourne aucun résultat" do
      before do
        stub_request(
          :get,
          "https://data.geopf.fr/geocodage/search/?q=20%20avenue%20de%20S%C3%A9gur,%20Paris,%2075007"
        ).to_return(
          status: 200,
          body: { type: "FeatureCollection", features: [] }.to_json,
          headers: {}
        )
      end

      it "ne met pas à jour l'usager" do
        described_class.new.perform(user.id)

        user.reload
        expect(user.city_code).to be_nil
      end
    end
  end
end
