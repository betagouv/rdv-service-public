describe TransactionalSms::FileAttente, type: :service do
  let(:rdv) { build(:rdv) }
  let(:user) { build(:user) }

  describe "#content" do
    subject { TransactionalSms::FileAttente.new(rdv, user).content }
    it { should include("Des créneaux se sont libérés plus tot") } # oh la belle faute
    it { should include("Cliquez pour voir les disponibilités") }
  end
end
