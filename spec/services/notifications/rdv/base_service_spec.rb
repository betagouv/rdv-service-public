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
    let(:user1) { build(:user, email: "jean@lol.fr", notify_by_email: true) }
    let(:user2) { build(:user, email: "martine@lol.fr", notify_by_email: true) }
    let(:rdv) { build(:rdv, starts_at: DateTime.now + 1.day, users: [user1, user2]) }
    it "should call send emails to both" do
      expect(service).to receive(:notify_user_by_mail).with(user1)
      expect(service).to receive(:notify_user_by_mail).with(user2)
      subject
    end
  end

  context "rdv has two users, one without email notifications" do
    let(:user1) { build(:user, email: "jean@lol.fr", notify_by_email: true) }
    let(:user2) { build(:user, email: "martine@lol.fr", notify_by_email: false) }
    let(:rdv) { build(:rdv, starts_at: DateTime.now + 1.day, users: [user1, user2]) }
    it "should call notify_user_by_email only for one user" do
      expect(service).to receive(:notify_user_by_mail).with(user1)
      expect(service).not_to receive(:notify_user_by_mail).with(user2)
      subject
    end
  end

  context "rdv has two users, one with missing email address" do
    let(:user1) { build(:user, email: "jean@lol.fr", notify_by_email: true) }
    let(:user2) { build(:user, email: nil, notify_by_email: false) }
    let(:rdv) { build(:rdv, starts_at: DateTime.now + 1.day, users: [user1, user2]) }
    it "should call notify_user_by_email only for one user" do
      expect(service).to receive(:notify_user_by_mail).with(user1)
      expect(service).not_to receive(:notify_user_by_mail).with(user2)
      subject
    end
  end

  context "rdv has two users, both with sms notifications" do
    # need to create for SMS because phone_number_formatted is computed in a before_save
    let(:user1) { create(:user, phone_number: "0601020304", notify_by_sms: true) }
    let(:user2) { create(:user, phone_number: "0601020305", notify_by_sms: true) }
    let(:rdv) { build(:rdv, starts_at: DateTime.now + 1.day, users: [user1, user2]) }
    it "should send SMS to both" do
      expect(service).to receive(:notify_user_by_sms).with(user1)
      expect(service).to receive(:notify_user_by_sms).with(user2)
      subject
    end
  end

  context "rdv has two users, one with SMS notifications disabled" do
    # need to create for SMS because phone_number_formatted is computed in a before_save
    let(:user1) { create(:user, phone_number: "0601020304", notify_by_sms: false) }
    let(:user2) { create(:user, phone_number: "0601020305", notify_by_sms: true) }
    let(:rdv) { build(:rdv, starts_at: DateTime.now + 1.day, users: [user1, user2]) }
    it "should send SMS to only one" do
      expect(service).not_to receive(:notify_user_by_sms).with(user1)
      expect(service).to receive(:notify_user_by_sms).with(user2)
      subject
    end
  end

  context "rdv has two users, one with a mising phone_number" do
    # need to create for SMS because phone_number_formatted is computed in a before_save
    let(:user1) { create(:user, phone_number: "0601020304", notify_by_sms: true) }
    let(:user2) { create(:user, phone_number: nil, notify_by_sms: true) }
    let(:rdv) { build(:rdv, starts_at: DateTime.now + 1.day, users: [user1, user2]) }
    it "should send SMS to only one" do
      expect(service).to receive(:notify_user_by_sms).with(user1)
      expect(service).not_to receive(:notify_user_by_sms).with(user2)
      subject
    end
  end
end
