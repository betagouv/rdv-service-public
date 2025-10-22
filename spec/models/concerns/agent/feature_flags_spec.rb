RSpec.describe Agent::FeatureFlags, type: :concern do
  describe "feature_enabled?" do
    let(:agent) { create(:agent, feature_flags: { new_planning: true }) }

    it "retourne true si la fonctionnalité est activée pour l’agent" do
      expect(create(:agent, feature_flags: { new_planning: true }).feature_enabled?("new_planning")).to be true
    end

    it "retourne false si la fonctionnalité n'est pas activée pour l’agent" do
      expect(create(:agent, feature_flags: {}).feature_enabled?("new_planning")).to be false
    end

    it "retourne false si la fonctionnalité est désactivée pour l’agent" do
      expect(create(:agent, feature_flags: { new_planning: false }).feature_enabled?("new_planning")).to be false
    end

    it "retourne false si la fonctionnalité n’est pas déclarée dans les constantes" do
      expect(agent.feature_enabled?("non_existent_feature")).to be false
    end
  end

  describe "enable_feature!" do
    let(:agent) { create(:agent) }

    it "active la fonctionnalité (idempotent)" do
      expect(agent.feature_enabled?("new_planning")).to be false
      agent.enable_feature!("new_planning")
      expect(agent.feature_enabled?("new_planning")).to be true

      # L'action est idempotente
      agent.enable_feature!("new_planning")
      expect(agent.feature_enabled?("new_planning")).to be true
    end

    it "invalide le modèle si la fonctionnalité n’existe pas" do
      expect(agent.feature_enabled?("new_planning")).to be false
      agent.enable_feature!("non_existent_feature")
      expect(agent.feature_enabled?("new_planning")).to be false
      expect(agent.errors.sole).to have_attributes(message: %(Invalid feature name: "non_existent_feature"))
    end
  end

  describe "disable_feature!" do
    let(:agent) { create(:agent, feature_flags: { new_planning: true }) }

    it "désactive la fonctionnalité (idempotent)" do
      expect(agent.feature_enabled?("new_planning")).to be true
      agent.disable_feature!("new_planning")
      expect(agent.feature_enabled?("new_planning")).to be false

      # L'action est idempotente
      agent.disable_feature!("new_planning")
      expect(agent.feature_enabled?("new_planning")).to be false
    end

    it "invalide le modèle si la fonctionnalité n’existe pas" do
      expect(agent.feature_enabled?("new_planning")).to be true
      agent.disable_feature!("non_existent_feature")
      expect(agent.feature_enabled?("new_planning")).to be true
      expect(agent.errors.sole).to have_attributes(message: %(Invalid feature name: "non_existent_feature"))
    end
  end
end
