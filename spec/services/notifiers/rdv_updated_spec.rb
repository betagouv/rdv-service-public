# frozen_string_literal: true
# TODO

describe Notifiers::RdvUpdated, type: :service do
  subject { described_class.perform_with(rdv, agent1) }

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:agent1) { build(:agent, first_name: "Sean", last_name: "PAUL") }
  let(:agent2) { build(:agent) }
  let(:rdv) { create(:rdv, starts_at: starts_at_initial, agents: [agent1, agent2], users: [user1, user2]) }

  before do
    stub_netsize_ok

    rdv.update!(starts_at: 4.days.from_now)
  end

  context "starts in more than 2 days" do
    let(:starts_at_initial) { 3.days.from_now }

    it "triggers sending mail to users but not to agents" do
      subject

      # SMS are sent to user1 and user2
      expect_sms_enqueued(phone_number: user1.phone_number_formatted)
      expect_sms_enqueued(phone_number: user2.phone_number_formatted)

      perform_enqueued_jobs # send emails so we can observe them
      expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array([user1.email, user2.email])
    end

    it "rdv_users_tokens_by_user_id attribute outputs the tokens" do
      allow(Devise.token_generator).to receive(:generate).and_return("t0k3n")
      notifier = described_class.new(rdv, agent1)
      notifier.perform
      expect(notifier.rdv_users_tokens_by_user_id).to eq({ user1.id => "t0k3n", user2.id => "t0k3n" })
    end
  end

  context "starts today or tomorrow" do
    let(:starts_at_initial) { 2.hours.from_now }

    it "triggers sending mails to both user and agents (except the one who initiated the change)" do
      subject
      perform_enqueued_jobs # send emails so we can observe them
      expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array([agent2.email, user1.email, user2.email])
    end

    it "doesnt send email if user participation is excused" do
      rdv.rdvs_users.where(user: user1).update(status: "excused")
      subject
      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array([agent2.email, user2.email])
    end
  end
end
