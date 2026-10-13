RSpec.describe AgentTwoFactorSessionState do
  let(:session) { {} }

  describe ".recent_2fa?" do
    it "est faux quand la double authentification n'a jamais été vérifiée" do
      expect(described_class.recent_2fa?(session)).to be(false)
    end

    it "est vrai pendant 30 minutes après la vérification" do
      described_class.mark_verified!(session)

      travel(29.minutes)
      expect(described_class.recent_2fa?(session)).to be(true)

      travel(2.minutes)
      expect(described_class.recent_2fa?(session)).to be(false)
    end

    it "est vrai quand un super admin usurpe l'identité de l'agent" do
      session[:super_admin_signed_in_as_agent] = true
      expect(described_class.recent_2fa?(session)).to be(true)
    end
  end

  describe ".pop_return_to!" do
    it "renvoie la page mémorisée et la retire de la session" do
      described_class.store_return_to!(session, "/agents/edit")

      expect(described_class.pop_return_to!(session)).to eq("/agents/edit")
      expect(session[described_class::RETURN_TO_SESSION_KEY]).to be_nil
    end

    it "renvoie la page d'accueil agent quand aucune page n'est mémorisée" do
      expect(described_class.pop_return_to!(session)).to eq("/")
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
