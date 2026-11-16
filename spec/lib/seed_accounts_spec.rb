RSpec.describe SeedAccounts do
  describe ".displayed?" do
    it "est faux en dehors du dev et des review apps" do
      expect(described_class.displayed?).to be(false)
    end

    it "est vrai sur une review app" do
      with_modified_env(IS_REVIEW_APP: "true") do
        expect(described_class.displayed?).to be(true)
      end
    end
  end

  describe ".agents et .users" do
    it "retourne les comptes listés dans db/seeds/seed_accounts.yml" do
      martine = described_class.agents.find { _1.slug == :martine }
      expect(martine.email).to eq("martine@demo.rdv-solidarites.fr")
      expect(martine.label).to be_present
      expect(described_class.users.map(&:slug)).to include(:patricia_duroy, :email_1)
    end

    it "a un email et un label pour chaque compte" do
      (described_class.agents + described_class.users).each do |account|
        expect(account.email).to match(/@/)
        expect(account.label).to be_present
      end
    end
  end

  describe ".password" do
    it "lit la variable d'environnement définie à l'exécution des seeds" do
      with_modified_env(DB_SEEDS_USERS_AND_AGENTS_PASSWORD: "Rdvservicepublictest1!") do
        expect(described_class.password).to eq("Rdvservicepublictest1!")
      end
    end
  end
end
