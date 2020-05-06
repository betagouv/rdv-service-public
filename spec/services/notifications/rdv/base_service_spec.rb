describe Notifications::Rdv::BaseService, type: :service do
  subject { Notifications::Rdv::BaseService.perform_with(rdv) }

  context "rdv dans le futur" do
    let(:rdv) { build(:rdv, starts_at: DateTime.now + 1.day) }
    it { should eq true }
  end

  context "rdv dans le passé" do
    let(:rdv) { build(:rdv, starts_at: DateTime.now - 1.day) }
    it { should eq false }
  end

  context "rdv dans le passé d'une heure seulement" do
    let(:rdv) { build(:rdv, starts_at: DateTime.now - 1.hour) }
    it { should eq false }
  end
end
