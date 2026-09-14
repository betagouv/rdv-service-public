RSpec.describe AgentTrustedDevice, type: :model do
  let(:agent) { create(:agent) }

  describe ".remember!" do
    it "crée une ligne en base avec le digest du token, pas le token en clair" do
      raw_token = described_class.remember!(agent)

      trusted_device = described_class.last
      expect(trusted_device.agent).to eq(agent)
      expect(trusted_device.token_digest).not_to eq(raw_token)
      expect(trusted_device.token_digest).to eq(described_class.digest(raw_token))
    end

    it "expire dans 7 jours" do
      travel_to Time.zone.local(2026, 1, 1, 12, 0, 0) do
        described_class.remember!(agent)
        expect(described_class.last.expires_at).to eq(Time.zone.local(2026, 1, 8, 12, 0, 0))
      end
    end
  end

  describe ".trusted?" do
    it "est vrai avec le bon token pour le bon agent" do
      raw_token = described_class.remember!(agent)
      expect(described_class.trusted?(agent, raw_token)).to be true
    end

    it "est faux avec un token vide" do
      described_class.remember!(agent)
      expect(described_class.trusted?(agent, nil)).to be false
    end

    it "est faux avec un mauvais token" do
      described_class.remember!(agent)
      expect(described_class.trusted?(agent, "un_autre_token")).to be false
    end

    it "est faux pour un autre agent" do
      raw_token = described_class.remember!(agent)
      other_agent = create(:agent)
      expect(described_class.trusted?(other_agent, raw_token)).to be false
    end

    it "est faux si le token est expiré" do
      raw_token = nil
      travel_to 8.days.ago do
        raw_token = described_class.remember!(agent)
      end
      expect(described_class.trusted?(agent, raw_token)).to be false
    end
  end
end
