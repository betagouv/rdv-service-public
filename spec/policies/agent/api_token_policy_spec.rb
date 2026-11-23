RSpec.describe Agent::ApiTokenPolicy, type: :policy do
  subject { described_class }

  let(:pundit_context) { AgentContext.new(agent) }
  let(:agent) { create(:agent) }

  permissions :index?, :new?, :create? do
    it { is_expected.to permit(pundit_context, ApiToken.new) }
  end

  describe "#destroy?" do
    context "avec sa propre clé" do
      let!(:api_token) { create(:api_token, agent:) }

      permissions(:destroy?) { it { is_expected.to permit(pundit_context, api_token) } }
    end

    context "avec la clé d'un autre agent" do
      let!(:api_token) { create(:api_token) }

      permissions(:destroy?) { it { is_expected.not_to permit(pundit_context, api_token) } }
    end
  end

  describe described_class::Scope do
    it "ne renvoie que les clés de l'agent" do
      create(:api_token, agent:, name: "Ma clé")
      create(:api_token, name: "Autre clé")

      expect(Agent::ApiTokenPolicy::Scope.new(pundit_context, ApiToken.all).resolve.pluck(:name)).to eq(["Ma clé"])
    end
  end
end
