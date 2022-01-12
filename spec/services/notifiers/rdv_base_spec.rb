# frozen_string_literal: true

class TestService < Notifiers::RdvBase
  def notify_user_by_mail(user); end

  def notify_user_by_sms(user); end

  def notify_agent(agent); end

  def rdvs_users_to_notify
    @rdv.rdvs_users.where(send_reminder_notification: true)
  end
end

describe Notifiers::RdvBase, type: :service do
  let(:service) { TestService.new(rdv, author) }

  describe "user notifications" do
    let(:author) { nil }

    context "rdv has one user with email notifications, but rdv is in the past" do
      let(:user1) { build(:user, notify_by_email: true) }
      let(:rdv) { create(:rdv, starts_at: 1.day.ago, users: [user1]) }

      it "sends email to user" do
        expect(service).not_to receive(:notify_user_by_mail).with(user1)
        service.perform
      end
    end

    context "rdv has one user with email notifications, but motif is not notified" do
      let(:user1) { build(:user, notify_by_email: true) }
      let(:motif) { build(:motif, :visible_and_not_notified) }
      let(:rdv) { create(:rdv, starts_at: 1.day.from_now, users: [user1], motif: motif) }

      it "sends email to user" do
        expect(service).not_to receive(:notify_user_by_mail).with(user1)
        service.perform
      end
    end

    context "rdv has two users, both with email notifications" do
      let(:user1) { build(:user, notify_by_email: true) }
      let(:user2) { build(:user, notify_by_email: true) }
      let(:rdv) { create(:rdv, starts_at: 1.day.from_now, users: [user1, user2]) }

      it "calls send emails to both" do
        expect(service).to receive(:notify_user_by_mail).with(user1)
        expect(service).to receive(:notify_user_by_mail).with(user2)
        service.perform
      end
    end

    context "rdv has two users, one without email notifications" do
      let(:user1) { build(:user, notify_by_email: true) }
      let(:user2) { build(:user, notify_by_email: false) }
      let(:rdv) { create(:rdv, starts_at: 1.day.from_now, users: [user1, user2]) }

      it "calls notify_user_by_email only for one user" do
        expect(service).to receive(:notify_user_by_mail).with(user1)
        expect(service).not_to receive(:notify_user_by_mail).with(user2)
        service.perform
      end
    end

    context "rdv has two users, both with sms notifications" do
      let(:user1) { build(:user, notify_by_sms: true) }
      let(:user2) { build(:user, notify_by_sms: true) }
      let(:rdv) { create(:rdv, starts_at: 1.day.from_now, users: [user1, user2]) }

      it "sends SMS to both" do
        expect(service).to receive(:notify_user_by_sms).with(user1)
        expect(service).to receive(:notify_user_by_sms).with(user2)
        service.perform
      end
    end

    context "rdv has two users, one with SMS notifications disabled" do
      let(:user1) { build(:user, notify_by_sms: false) }
      let(:user2) { build(:user, notify_by_sms: true) }
      let(:rdv) { create(:rdv, starts_at: 1.day.from_now, users: [user1, user2]) }

      it "sends SMS to only one" do
        expect(service).not_to receive(:notify_user_by_sms).with(user1)
        expect(service).to receive(:notify_user_by_sms).with(user2)
        service.perform
      end
    end

    context "rdv has one user with one responsible" do
      let(:responsible) { build(:user) }
      let(:user) { build(:user, responsible: responsible) }
      let(:rdv) { create(:rdv, starts_at: 1.day.from_now, users: [user]) }

      it "sends emails to only the responsible" do
        expect(service).not_to receive(:notify_user_by_sms).with(user)
        expect(service).to receive(:notify_user_by_sms).with(responsible)
        expect(service).not_to receive(:notify_user_by_mail).with(user)
        expect(service).to receive(:notify_user_by_mail).with(responsible)
        service.perform
      end
    end
  end

  describe "agent notifications" do
    context "motif is not_notified" do
      let(:author) { build(:agent) }
      let(:agent) { build(:agent) }
      let(:motif) { build(:motif, :visible_and_not_notified) }
      let(:rdv) { create(:rdv, starts_at: 1.day.from_now, agents: [agent], motif: motif) }

      it "agent is notified anyway" do
        expect(service).to receive(:notify_agent).with(agent)
        service.perform
      end
    end

    describe "agents_rdv_notifications_level" do
      let(:agent) { build(:agent, rdv_notifications_level: rdv_notifications_level) }
      let(:user) { build(:user) }
      let(:rdv) { create(:rdv, starts_at: rdv_date, agents: [agent], users: [user]) }

      context "level is all" do
        let(:author) { agent }
        let(:rdv_notifications_level) { "all" }
        let(:rdv_date) { 1.week.from_now }

        it "sends notification" do
          expect(service).to receive(:notify_agent).with(agent)
          service.perform
        end
      end

      context "level is others and rdv is made by agent themselves" do
        let(:author) { agent }
        let(:rdv_notifications_level) { "others" }
        let(:rdv_date) { 1.week.from_now }

        it "doesn’t send notification" do
          expect(service).not_to receive(:notify_agent).with(agent)
          service.perform
        end
      end

      context "level is others and rdv is made by someone else" do
        let(:author) { build(:agent) }
        let(:rdv_notifications_level) { "others" }
        let(:rdv_date) { 1.week.from_now }

        it "sends notification" do
          expect(service).to receive(:notify_agent).with(agent)
          service.perform
        end
      end

      context "level is soon and rdv is for next week" do
        let(:author) { build(:agent) }
        let(:rdv_notifications_level) { "soon" }
        let(:rdv_date) { 1.week.from_now }

        it "doesn’t send notification" do
          expect(service).not_to receive(:notify_agent).with(agent)
          service.perform
        end
      end

      context "level is soon and rdv is for tomorrow" do
        let(:author) { build(:agent) }
        let(:rdv_notifications_level) { "soon" }
        let(:rdv_date) { 1.day.from_now }

        it "sends notification" do
          expect(service).to receive(:notify_agent).with(agent)
          service.perform
        end
      end

      context "level is none" do
        let(:author) { build(:agent) }
        let(:rdv_notifications_level) { "none" }
        let(:rdv_date) { 1.day.from_now }

        it "doesn’t send notification" do
          expect(service).not_to receive(:notify_agent).with(agent)
          service.perform
        end
      end
    end
  end
end
