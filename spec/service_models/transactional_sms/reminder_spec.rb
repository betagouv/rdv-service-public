describe TransactionalSms::Reminder, type: :service do
  let(:pmi) { build(:service, short_name: "PMI") }
  let(:motif) { build(:motif, service: pmi) }
  let(:lieu) { build(:lieu, name: "MDS Centre", address: "10 rue d'ici") }
  let(:rdv) { build(:rdv, motif: motif, lieu: lieu, starts_at: Time.zone.local(2021, 12, 10, 13, 10)) }
  let(:user) { build(:user) }

  describe "#content" do
    subject { TransactionalSms::Reminder.new(rdv, user).content }
    it { should include("Rappel RDV PMI le 10 déc. à 13h10") }
    it { should include("MDS Centre (10 rue d'ici)") }
    it { should include("Infos et annulation") }
  end
end
