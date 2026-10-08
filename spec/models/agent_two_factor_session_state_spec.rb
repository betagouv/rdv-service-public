RSpec.describe AgentTwoFactorSessionState do
  let(:session) { {} }

  describe ".fresh?" do
    it "est faux quand la double authentification n'a jamais été vérifiée" do
      expect(described_class.fresh?(session)).to be(false)
    end

    it "est vrai pendant 30 minutes après la vérification" do
      described_class.mark_verified!(session)

      travel(29.minutes)
      expect(described_class.fresh?(session)).to be(true)

      travel(2.minutes)
      expect(described_class.fresh?(session)).to be(false)
    end
  end

  describe ".pop_return_to!" do
    it "renvoie la page mémorisée et la retire de la session" do
      described_class.store_return_to!(session, "/agents/edit")

      expect(described_class.pop_return_to!(session)).to eq("/agents/edit")
      expect(session[described_class::RETURN_TO_SESSION_KEY]).to be_nil
    end

    it "renvoie la liste des exports quand aucune page n'est mémorisée" do
      expect(described_class.pop_return_to!(session)).to eq("/agents/exports")
    end

    it "renvoie la liste des exports quand la page mémorisée est un téléchargement d'export" do
      described_class.store_return_to!(session, "/agents/exports/42/download")

      expect(described_class.pop_return_to!(session)).to eq("/agents/exports")
    end
  end

  describe ".clear!" do
    it "retire la vérification et la page mémorisée de la session" do
      described_class.mark_verified!(session)
      described_class.store_return_to!(session, "/agents/edit")

      described_class.clear!(session)

      expect(session).to be_empty
    end
  end
end
