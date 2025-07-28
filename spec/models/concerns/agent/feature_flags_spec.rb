RSpec.describe Agent::FeatureFlags, type: :concern do
  describe "feature_enabled?" do
    let(:agent) { create(:agent, feature_flags: { new_planning: true }) }

    it "retourne true si la fonctionnalité est activée pour l’agent" do
      expect(agent.feature_enabled?("new_planning")).to be true
    end

    it "retourne false si la fonctionnalité n’est pas activée pour l’agent" do
      expect(agent.feature_enabled?("non_existent_feature")).to be false
    end
  end

  describe "enable_feature" do
    let(:agent) { create(:agent) }

    it "active la fonctionnalité" do
      agent.enable_feature("new_planning")
      expect(agent.feature_enabled?("new_planning")).to be true
    end

    it "ne fait rien si la fonctionnalité n’existe pas" do
      agent.enable_feature("invalid_feature")
      expect(agent.feature_enabled?("invalid_feature")).to be false
    end

    it "crée le hash si feature_flags est nil" do
      agent.feature_flags = nil
      agent.enable_feature("new_planning")
      expect(agent.feature_flags).to eq({ "new_planning" => true })
    end
  end

  describe "disable_feature" do
    let(:agent) { create(:agent, feature_flags: { new_planning: true }) }

    it "désactive la fonctionnalité" do
      agent.disable_feature("new_planning")
      expect(agent.feature_enabled?("new_planning")).to be false
    end

    it "ne fait rien si on essaye de désactiver une fonctionnalité inexistante" do
      expect { agent.disable_feature("non_existent_feature") }.not_to raise_error
      expect(agent.feature_flags).to eq({ "new_planning" => true })
    end
  end

  describe "toggle_feature!" do
    let(:agent) { create(:agent, feature_flags: { new_planning: true }) }

    it "désactive une fonctionnalité activée" do
      agent.toggle_feature!("new_planning")
      expect(agent.reload.feature_enabled?("new_planning")).to be false
    end

    it "active une fonctionnalité désactivée" do
      agent.disable_feature("new_planning")
      agent.toggle_feature!("new_planning")
      expect(agent.reload.feature_enabled?("new_planning")).to be true
    end

    it "ne fait rien si la fonctionnalité n’existe pas" do
      expect { agent.toggle_feature!("invalid_feature") }.not_to raise_error
      expect(agent.reload.feature_flags).to eq({ "new_planning" => true })
    end
  end
end
