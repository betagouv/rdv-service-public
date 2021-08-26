# frozen_string_literal: true

describe Agent::WebhookEndpointPolicy, type: :policy do
  subject { described_class }

  let(:pundit_context) { AgentContext.new(agent) }
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:webhook) { create(:webhook_endpoint, organisation: organisation) }

  context "with territory admin agent" do
    let(:agent) { create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory]) }

    permissions(:agent_territory_admin?) { it { is_expected.to permit(pundit_context, webhook) } }
  end

  context "with admin agent not on territory" do
    let(:agent) { create(:agent, admin_role_in_organisations: [organisation], role_in_territories: []) }

    permissions(:agent_territory_admin?) { it { is_expected.not_to permit(pundit_context, webhook) } }
  end
end

describe Agent::WebhookEndpointPolicy::Scope, type: :policy do
  describe "#resolve?" do
    let(:organisation) { create(:organisation) }

    context "with an admin agent" do
      let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

      it "allow to see webhook from same territory" do
        webhook = create(:webhook_endpoint, organisation: organisation)
        webhook_policy = described_class.new(AgentContext.new(agent), WebhookEndpoint)
        expect(webhook_policy.resolve).to include(webhook)
      end
    end
  end
end
