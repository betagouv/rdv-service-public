RSpec.describe Agent::FeatureFlags, type: :concern do
  before do
    stub_const("Agent::FeatureFlags::AVAILABLE_FEATURES", %w[feature_1 feature_2])
  end

  describe "feature_enabled?" do
    let(:agent) { create(:agent, feature_flags: { feature_1: true }) }

    it "retourne true si la fonctionnalité est activée pour l’agent" do
      expect(create(:agent, feature_flags: { feature_1: true }).feature_enabled?("feature_1")).to be true
    end

    it "retourne false si la fonctionnalité n'est pas activée pour l’agent" do
      expect(create(:agent, feature_flags: {}).feature_enabled?("feature_1")).to be false
    end

    it "retourne false si la fonctionnalité est désactivée pour l’agent" do
      expect(create(:agent, feature_flags: { feature_1: false }).feature_enabled?("feature_1")).to be false
    end

    it "retourne false si la fonctionnalité n’est pas déclarée dans les constantes" do
      expect(agent.feature_enabled?("non_existent_feature")).to be false
    end
  end

  describe "enable_feature!" do
    let(:agent) { create(:agent) }

    it "active la fonctionnalité (idempotent)" do
      expect(agent.feature_enabled?("feature_1")).to be false
      agent.enable_feature!("feature_1")
      expect(agent.feature_enabled?("feature_1")).to be true

      # L'action est idempotente
      agent.enable_feature!("feature_1")
      expect(agent.feature_enabled?("feature_1")).to be true
    end

    it "lève une erreur si la fonctionnalité n’existe pas" do
      expect do
        agent.enable_feature!("non_existent_feature")
      end.to raise_error(%(Invalid feature name: "non_existent_feature"))
    end
  end

  describe "disable_feature!" do
    let(:agent) { create(:agent, feature_flags: { feature_1: true }) }

    it "désactive la fonctionnalité (idempotent)" do
      expect(agent.feature_enabled?("feature_1")).to be true
      agent.disable_feature!("feature_1")
      expect(agent.feature_enabled?("feature_1")).to be false

      # L'action est idempotente
      agent.disable_feature!("feature_1")
      expect(agent.feature_enabled?("feature_1")).to be false
    end

    it "lève une erreur si la fonctionnalité n’existe pas" do
      expect do
        agent.disable_feature!("non_existent_feature")
      end.to raise_error(%(Invalid feature name: "non_existent_feature"))
    end
  end
end
