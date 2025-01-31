RSpec.describe Agent::WebhookEndpointPolicy do
  subject { described_class }

  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:webhook) { create(:webhook_endpoint, organisations: [organisation]) }

  context "with territory admin agent" do
    let(:agent) { create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory]) }

    permissions(:create?) { it { is_expected.to permit(agent, webhook) } }
  end

  context "with admin agent not on territory" do
    let(:agent) { create(:agent, admin_role_in_organisations: [organisation], role_in_territories: []) }

    permissions(:create?) { it { is_expected.not_to permit(agent, webhook) } }
  end
end

RSpec.describe Agent::WebhookEndpointPolicy::Scope do
  describe "#resolve?" do
    let(:organisation) { create(:organisation) }

    context "with an admin agent with no territory role" do
      let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

      it "does not allow to see webhook from same territory" do
        webhook = create(:webhook_endpoint, organisations: [organisation])
        webhook_policy = described_class.new(agent, WebhookEndpoint)
        expect(webhook_policy.resolve).not_to include(webhook)
      end
    end

    context "with an agent with territory role but that belongs to no organisation" do
      let(:agent) { create(:agent, role_in_territories: [organisation.territory]) }

      it "allows to see webhook from the territory" do
        webhook = create(:webhook_endpoint, organisations: [organisation])
        webhook_policy = described_class.new(agent, WebhookEndpoint)
        expect(webhook_policy.resolve).to include(webhook)
      end
    end
  end
end
