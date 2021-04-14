describe TransactionalSms::FileAttente, type: :service do
  let(:rdv) { build(:rdv) }
  let(:user) { build(:user) }

  describe "#content" do
    subject { described_class.new(rdv, user).content }

    it { is_expected.to include("Des créneaux se sont libérés plus tot") } # oh la belle faute
    it { is_expected.to include("Cliquez pour voir les disponibilités") }
  end
end
