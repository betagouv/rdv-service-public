RSpec.describe CartoANCT do
  describe ".fetch_and_merge_metrics" do
    it "merges siret from both databases" do
      stub_request(:post, /#{MetabaseApi::HOST_URL}/)
        .with { _1.body.include?("territories") && _1.body.exclude?("rdvsp") }
        .to_return(body: [{ siret: "13002526500013", tu: 2 }].to_json)
      stub_request(:post, /#{MetabaseApi::HOST_URL}/)
        .with { _1.body.include?("territories") && _1.body.include?("rdvsp") }
        .to_return(body: [{ siret: "13002526500013", tu: 30 }, { siret: "12345678901234", tu: 10 }].to_json)

      expected_merged_results = [
        { metrics: { tu: 10 }, siret: "12345678901234" },
        { metrics: { tu: 32 }, siret: "13002526500013" },
      ]
      expect(described_class.fetch_and_merge_metrics).to match_array(expected_merged_results)
    end
  end
end
