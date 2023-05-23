# frozen_string_literal: true

describe GeoCoding do
  include described_class

  describe "#find_geo_coordinates" do
    before do
      stub_request(
        :get,
        "https://api-adresse.data.gouv.fr/search/?q=03%20Rue%20Lambert,%20Paris,%2075018"
      ).to_return(status: 200, body: file_fixture("geocode_result.json").read, headers: {})
    end

    it "returns the coordinates" do
      expect(find_geo_coordinates("03 Rue Lambert, Paris, 75018")).to eq([2.372095, 48.88393])
    end
  end
end
