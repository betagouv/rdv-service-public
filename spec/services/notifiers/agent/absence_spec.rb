RSpec.describe Notifiers::Agent::Absence do
  describe "#created" do
    let(:absence) { create(:absence, agent:) }

    context "quand l’agent n’a pas de mail" do
      let(:agent) { create(:agent, :intervenant, absence_notification_level: "all") }

      it "ne notifie pas l’agent" do
        described_class.new(absence).created!
        expect(enqueued_jobs).to be_empty
      end
    end

    context 'quand l’agent a un mail et le niveau de notification est "all"' do
      let(:agent) { create(:agent, absence_notification_level: "all") }

      it "notifie l’agent" do
        described_class.new(absence).created!
        expect(enqueued_jobs.last["job_class"]).to eq("ApplicationMailerDeliveryJob")
      end
    end

    context 'quand l’agent a un mail mais le niveau de notification est à "none"' do
      let(:agent) { create(:agent, absence_notification_level: "none") }

      it "ne notifie pas l’agent" do
        described_class.new(absence).created!
        expect(enqueued_jobs).to be_empty
      end
    end
  end
end
