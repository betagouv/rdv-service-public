RSpec.describe CartoANCT do
  describe ".fetch_and_merge_metrics" do
    it "merges siret and insee" do
      stub_request(:post, /#{MetabaseApi::HOST_URL}/)
        .with { _1.uri.to_s.include?("code_insee") && _1.uri.to_s.include?("rdvs%") }
        .to_return(body: [{ insee: "01001", tu: 200 }, { insee: "01006", tu: 100 }].to_json)
      stub_request(:post, /#{MetabaseApi::HOST_URL}/)
        .with { _1.uri.to_s.include?("code_insee") && _1.uri.to_s.include?("rdvsp%") }
        .to_return(body: [{ insee: "01001", tu: 44 }, { insee: "01006", tu: 33 }].to_json)

      stub_request(:post, /#{MetabaseApi::HOST_URL}/)
        .with { _1.uri.to_s.include?("siret") && _1.uri.to_s.include?("rdvs%") }
        .to_return(body: [{ siret: "13002526500013", tu: 2 }].to_json)
      stub_request(:post, /#{MetabaseApi::HOST_URL}/)
        .with { _1.uri.to_s.include?("siret") && _1.uri.to_s.include?("rdvsp%") }
        .to_return(body: [{ siret: "13002526500013", tu: 30 }, { siret: "12345678901234", tu: 10 }].to_json)

      expected_merged_results = [
        { insee: "01001", metrics: { tu: 244 } },
        { insee: "01006", metrics: { tu: 133 } },
        { metrics: { tu: 10 }, siret: "12345678901234" },
        { metrics: { tu: 32 }, siret: "13002526500013" },
      ]
      expect(described_class.fetch_and_merge_metrics).to match_array(expected_merged_results)
    end
  end
end
