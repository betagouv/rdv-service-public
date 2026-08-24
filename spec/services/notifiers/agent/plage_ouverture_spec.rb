RSpec.describe Notifiers::Agent::PlageOuverture do
  describe "#created" do
    let(:plage_ouverture) { create(:plage_ouverture, agent:) }

    context "quand l’agent n’a pas de mail" do
      let(:agent) { create(:agent, :intervenant, plage_ouverture_notification_level: "all") }

      it "ne notifie pas l’agent" do
        described_class.new(plage_ouverture).created!
        expect(enqueued_jobs).to be_empty
      end
    end

    context 'quand l’agent a un mail et le niveau de notification est "all"' do
      let(:agent) { create(:agent, plage_ouverture_notification_level: "all") }

      it "notifie l’agent" do
        described_class.new(plage_ouverture).created!
        expect(enqueued_jobs.last["job_class"]).to eq("ApplicationMailerDeliveryJob")
      end
    end

    context 'quand l’agent a un mail mais le niveau de notification est à "none"' do
      let(:agent) { create(:agent, plage_ouverture_notification_level: "none") }

      it "ne notifie pas l’agent" do
        described_class.new(plage_ouverture).created!
        expect(enqueued_jobs).to be_empty
      end
    end
  end
end
