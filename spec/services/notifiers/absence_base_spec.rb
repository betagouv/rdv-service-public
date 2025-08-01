RSpec.describe Notifiers::AbsenceBase, type: :service do
  describe "perform" do
    let(:absence) { build(:absence, agent:) }

    context "quand l’agent n’a pas de mail" do
      let(:agent) { build(:agent, email: nil, absence_notification_level: "all") }

      it "ne notifie pas l’agent" do
        service = described_class.new(absence)
        expect(service).not_to receive(:notify)
        service.perform
      end
    end

    context 'quand l’agent a un mail et le niveau de notification est "all"' do
      let(:agent) { build(:agent, absence_notification_level: "all") }

      it "notifie l’agent" do
        service = described_class.new(absence)
        expect(service).to receive(:notify)
        service.perform
      end
    end

    context 'quand l’agent a un mail mais le niveau de notification est à "none"' do
      let(:agent) { build(:agent, absence_notification_level: "none") }

      it "ne notifie pas l’agent" do
        service = described_class.new(absence)
        expect(service).not_to receive(:notify)
        service.perform
      end
    end
  end
end
