RSpec.describe Redis do
  describe "#with_connection" do
    # L'usage d'une pool de connexion offre de bien meilleures performances,
    # ce test a donc été ajouté pour inciter à continuer d'en utiliser une.
    it "is pooled" do
      allow(Redis::CONNECTION_POOL).to receive(:with).and_call_original

      described_class.with_connection { |redis| redis.set("key", "value") }
      described_class.with_connection { |redis| expect(redis.get("key")).to eq("value") }

      expect(Redis::CONNECTION_POOL).to have_received(:with).twice
    end
  end
end
