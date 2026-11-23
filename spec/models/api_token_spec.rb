RSpec.describe ApiToken do
  describe "génération à la création" do
    it "génère un token préfixé rdvsp_pat_ et ne stocke que son digest SHA256" do
      token = create(:api_token)

      expect(token.raw_token).to start_with("rdvsp_pat_")
      expect(token.token_digest).to eq(Digest::SHA256.hexdigest(token.raw_token))
      expect(described_class.column_names).not_to include("raw_token") # le token en clair n'est jamais stocké
    end
  end

  describe ".authenticate" do
    let!(:token) { create(:api_token) }

    it "retrouve le token actif par son token en clair" do
      expect(described_class.authenticate(token.raw_token)).to eq(token)
    end

    it "renvoie nil pour un token sans le préfixe rdvsp_pat_" do
      expect(described_class.authenticate("autre_chose")).to be_nil
    end

    it "renvoie nil pour un token inconnu" do
      expect(described_class.authenticate("rdvsp_pat_inconnu")).to be_nil
    end

    it "renvoie nil si le token est révoqué" do
      token.revoke!
      expect(described_class.authenticate(token.raw_token)).to be_nil
    end

    it "renvoie nil si le token est expiré" do
      token.update_column(:expires_at, 1.hour.ago) # rubocop:disable Rails/SkipsModelValidations
      expect(described_class.authenticate(token.raw_token)).to be_nil
    end
  end

  describe "DURATIONS" do
    it "propose 9 durées entre 24h et 1 an, exprimées en mois à partir de 14 jours" do
      durations = described_class::DURATIONS
      expect(durations.size).to eq(9)
      expect(durations.first).to eq(["24 heures", 24.hours])
      expect(durations.last).to eq(["1 an", 12.months])
      expect(durations.map(&:last)).to all(be_between(24.hours, 12.months))
    end
  end

  describe "#touch_last_used!" do
    it "met à jour last_used_at" do
      token = create(:api_token)
      expect { token.touch_last_used! }.to change { token.reload.last_used_at }.from(nil)
    end

    it "n'écrit pas en base si last_used_at date de moins d'une minute" do
      token = create(:api_token, last_used_at: 30.seconds.ago)
      expect { token.touch_last_used! }.not_to change { token.reload.last_used_at }
    end
  end

  describe "validations" do
    it "refuse un nom de plus de 255 caractères" do
      token = build(:api_token, name: "a" * 256)
      expect(token).not_to be_valid
      expect(token.errors[:name]).to be_present
    end

    it "refuse une 11e clé active pour le même agent" do
      agent = create(:agent)
      create_list(:api_token, 10, agent:)

      onzieme = build(:api_token, agent:)
      expect(onzieme).not_to be_valid
      expect(onzieme.errors[:base].join).to include("nombre maximum")
    end

    it "accepte une nouvelle clé si les 10 existantes sont révoquées" do
      agent = create(:agent)
      create_list(:api_token, 10, agent:).each(&:revoke!)

      expect(build(:api_token, agent:)).to be_valid
    end
  end
end
