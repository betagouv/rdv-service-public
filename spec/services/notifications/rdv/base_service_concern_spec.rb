# frozen_string_literal: true

class TestService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  def notify_user_by_mail(user); end

  def notify_user_by_sms(user); end
end

describe Notifications::Rdv::BaseServiceConcern, type: :service do
  let(:service) { TestService.new(rdv) }

  describe "user notifications" do
    context "rdv has one user with email notifications, but rdv is in the past" do
      let(:user1) { build(:user, notify_by_email: true) }
      let(:rdv) { build(:rdv, starts_at: Time.zone.now - 1.day, users: [user1]) }

      it "sends email to user" do
        expect(service).not_to receive(:notify_user_by_mail).with(user1)
        service.perform
      end
    end

    context "rdv has one user with email notifications, but motif is not notified" do
      let(:user1) { build(:user, notify_by_email: true) }
      let(:motif) { build(:motif, :visible_and_not_notified) }
      let(:rdv) { build(:rdv, starts_at: Time.zone.now + 1.day, users: [user1], motif: motif) }

      it "sends email to user" do
        expect(service).not_to receive(:notify_user_by_mail).with(user1)
        service.perform
      end
    end

    context "rdv has two users, both with email notifications" do
      let(:user1) { build(:user, notify_by_email: true) }
      let(:user2) { build(:user, notify_by_email: true) }
      let(:rdv) { build(:rdv, starts_at: Time.zone.now + 1.day, users: [user1, user2]) }

      it "calls send emails to both" do
        expect(service).to receive(:notify_user_by_mail).with(user1)
        expect(service).to receive(:notify_user_by_mail).with(user2)
        service.perform
      end
    end

    context "rdv has two users, one without email notifications" do
      let(:user1) { build(:user, notify_by_email: true) }
      let(:user2) { build(:user, notify_by_email: false) }
      let(:rdv) { build(:rdv, starts_at: Time.zone.now + 1.day, users: [user1, user2]) }

      it "calls notify_user_by_email only for one user" do
        expect(service).to receive(:notify_user_by_mail).with(user1)
        expect(service).not_to receive(:notify_user_by_mail).with(user2)
        service.perform
      end
    end

    context "rdv has two users, both with sms notifications" do
      let(:user1) { build(:user, notify_by_sms: true) }
      let(:user2) { build(:user, notify_by_sms: true) }
      let(:rdv) { build(:rdv, starts_at: Time.zone.now + 1.day, users: [user1, user2]) }

      it "sends SMS to both" do
        expect(service).to receive(:notify_user_by_sms).with(user1)
        expect(service).to receive(:notify_user_by_sms).with(user2)
        service.perform
      end
    end

    context "rdv has two users, one with SMS notifications disabled" do
      let(:user1) { build(:user, notify_by_sms: false) }
      let(:user2) { build(:user, notify_by_sms: true) }
      let(:rdv) { build(:rdv, starts_at: Time.zone.now + 1.day, users: [user1, user2]) }

      it "sends SMS to only one" do
        expect(service).not_to receive(:notify_user_by_sms).with(user1)
        expect(service).to receive(:notify_user_by_sms).with(user2)
        service.perform
      end
    end
  end
end
