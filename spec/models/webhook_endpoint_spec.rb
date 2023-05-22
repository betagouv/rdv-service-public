# frozen_string_literal: true

describe WebhookEndpoint, type: :model do
  describe "target_url validation" do
    subject { webhook_endpoint.valid? }

    let(:organisation) { create(:organisation) }
    let(:webhook_endpoint) { build(:webhook_endpoint, organisation_id: organisation.id, target_url: target_url) }
    let!(:other_webhook_endpoint) { create(:webhook_endpoint, organisation_id: organisation.id, target_url: "https://www.taken_url.com") }

    context "when the target_url is unique in the organisation_id scope" do
      let(:target_url) { "https://www.rdv-insertion.fr/rdv_solidarites_webhooks" }

      it "is valid" do
        expect(subject).to eq(true)
      end
    end

    context "when the target_url is already taken in the organisation_id scope" do
      let(:target_url) { "https://www.taken_url.com" }

      it "is not valid" do
        expect(subject).to eq(false)
      end
    end
  end

  describe "#subscriptions_validity" do
    subject { webhook_endpoint.valid? }

    let(:organisation) { create(:organisation) }
    let(:webhook_endpoint) { build(:webhook_endpoint, organisation_id: organisation.id, subscriptions: subscriptions) }

    context "when the subscriptions array is valid" do
      let(:subscriptions) { %w[rdv absence plage_ouverture user motif lieu agent agent_role referent_assignation] }

      it "is valid" do
        expect(subject).to eq(true)
      end
    end

    context "when the target_url is already taken in the organisation_id scope" do
      let(:subscriptions) { %w[user organisation wrong_value] }

      it "is not valid" do
        expect(subject).to eq(false)
      end
    end
  end
end
