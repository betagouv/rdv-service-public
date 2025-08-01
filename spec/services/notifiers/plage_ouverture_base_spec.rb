RSpec.describe Notifiers::PlageOuvertureBase do
  describe "perform" do
    let(:plage_ouverture) { build(:plage_ouverture, agent:) }

    context "quand l’agent n’a pas de mail" do
      let(:agent) { build(:agent, email: nil, plage_ouverture_notification_level: "all") }

      it "ne notifie pas l’agent" do
        service = described_class.new(plage_ouverture)
        expect(service).not_to receive(:notify)
        service.perform
      end
    end

    context 'quand l’agent a un mail et le niveau de notification est "all"' do
      let(:agent) { build(:agent, plage_ouverture_notification_level: "all") }

      it "notifie l’agent" do
        service = described_class.new(plage_ouverture)
        expect(service).to receive(:notify)
        service.perform
      end
    end

    context 'quand l’agent a un mail mais le niveau de notification est à "none"' do
      let(:agent) { build(:agent, plage_ouverture_notification_level: "none") }

      it "ne notifie pas l’agent" do
        service = described_class.new(plage_ouverture)
        expect(service).not_to receive(:notify)
        service.perform
      end
    end
  end
end
