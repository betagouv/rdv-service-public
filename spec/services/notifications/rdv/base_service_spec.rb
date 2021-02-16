class TestService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  def notify_user_by_mail(user); end

  def notify_user_by_sms(user); end
end

describe Notifications::Rdv::BaseServiceConcern, type: :service do
  let(:service) { TestService.new(rdv) }
  subject { service.perform }

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

  context "rdv has two users, both with email notifications" do
    let(:user1) { build(:user) }
    let(:user2) { build(:user) }
    let(:rdv) { build(:rdv, starts_at: DateTime.now + 1.day, users: [user1, user2]) }
    before do
      allow(user1).to receive(:notifiable_by_email?).and_return(true)
      allow(user2).to receive(:notifiable_by_email?).and_return(true)
    end
    it "should call send emails to both" do
      expect(service).to receive(:notify_user_by_mail).with(user1)
      expect(service).to receive(:notify_user_by_mail).with(user2)
      subject
    end
  end

  context "rdv has two users, one without email notifications" do
    let(:user1) { build(:user) }
    let(:user2) { build(:user) }
    let(:rdv) { build(:rdv, starts_at: DateTime.now + 1.day, users: [user1, user2]) }
    before do
      allow(user1).to receive(:notifiable_by_email?).and_return(true)
      allow(user2).to receive(:notifiable_by_email?).and_return(false)
    end
    it "should call notify_user_by_email only for one user" do
      expect(service).to receive(:notify_user_by_mail).with(user1)
      expect(service).not_to receive(:notify_user_by_mail).with(user2)
      subject
    end
  end

  context "rdv has two users, both with sms notifications" do
    let(:user1) { build(:user) }
    let(:user2) { build(:user) }
    let(:rdv) { build(:rdv, starts_at: DateTime.now + 1.day, users: [user1, user2]) }
    before do
      allow(user1).to receive(:notifiable_by_sms?).and_return(true)
      allow(user2).to receive(:notifiable_by_sms?).and_return(true)
    end
    it "should send SMS to both" do
      expect(service).to receive(:notify_user_by_sms).with(user1)
      expect(service).to receive(:notify_user_by_sms).with(user2)
      subject
    end
  end

  context "rdv has two users, one with SMS notifications disabled" do
    let(:user1) { build(:user) }
    let(:user2) { build(:user) }
    let(:rdv) { build(:rdv, starts_at: DateTime.now + 1.day, users: [user1, user2]) }
    before do
      allow(user1).to receive(:notifiable_by_sms?).and_return(false)
      allow(user2).to receive(:notifiable_by_sms?).and_return(true)
    end
    it "should send SMS to only one" do
      expect(service).not_to receive(:notify_user_by_sms).with(user1)
      expect(service).to receive(:notify_user_by_sms).with(user2)
      subject
    end
  end
end
