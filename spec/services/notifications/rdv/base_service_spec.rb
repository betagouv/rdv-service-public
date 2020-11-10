class TestService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern
end

describe Notifications::Rdv::BaseServiceConcern, type: :service do
  subject { TestService.perform_with(rdv) }

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

  context "rdv avec un motif visible mais sans notification" do
    let(:motif) { build(:motif, :visible_and_not_notified) }
    let(:rdv) { build(:rdv, starts_at: DateTime.now + 1.day, motif: motif) }
    it { should eq false }
  end
end
