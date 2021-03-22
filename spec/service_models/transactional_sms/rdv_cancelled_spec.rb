describe TransactionalSms::RdvCancelled, type: :service do
  let(:pmi) { build(:service, short_name: "PMI") }
  let(:motif) { build(:motif, service: pmi) }
  let(:rdv) { build(:rdv, motif: motif, starts_at: Time.zone.local(2021, 12, 10, 13, 10)) }
  let(:user) { build(:user) }

  describe "#content" do
    subject { TransactionalSms::RdvCancelled.new(rdv, user).content }
    it { should include("RDV PMI vendredi 10/12 à 13h10 a été annulé") }
    it { should include("Allez sur https://rdv-solidarites.fr pour reprendre RDV") }
  end
end
