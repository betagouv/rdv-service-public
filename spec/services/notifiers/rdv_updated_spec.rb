# frozen_string_literal: true

describe Notifiers::RdvUpdated, type: :service do
  subject { described_class.perform_with(rdv, agent1) }

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:agent1) { build(:agent, first_name: "Sean", last_name: "PAUL") }
  let(:agent2) { build(:agent) }
  let(:rdv) { create(:rdv, starts_at: starts_at_initial, agents: [agent1, agent2], users: [user1, user2]) }
  # let(:rdvs_users_relation) { RdvsUser.where(id: [rdv_user1.id, rdv_user2.id]) }
  # let(:rdvs_users_array) { [rdv_user1, rdv_user2] }
  # let(:token1) { "123456" }
  # let(:token2) { "56789" }

  before do
    stub_netsize_ok

    rdv.update!(starts_at: 4.days.from_now)

    # allow(Users::RdvMailer).to receive(:with).and_call_original
    # allow(Agents::RdvMailer).to receive(:with).and_call_original
    # allow(rdv).to receive(:rdvs_users).and_return(rdvs_users_relation)
    # allow(rdvs_users_relation).to receive_message_chain(:where, :not, :where).with(send_lifecycle_notifications: true)
    #   .and_return(rdvs_users_array.select(&:send_lifecycle_notifications))
    # allow(rdv_user1).to receive(:new_raw_invitation_token).and_return(token1)
    # allow(rdv_user2).to receive(:new_raw_invitation_token).and_return(token2)
  end

  context "starts in more than 2 days" do
    let(:starts_at_initial) { 3.days.from_now }

    it "triggers sending mail to users but not to agents" do
      # expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user1, token: token1 })
      # expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user2, token: token2 })
      # expect(Agents::RdvMailer).not_to receive(:with)
      subject

      # SMS are sent to user1 and user2
      expect_sms_enqueued(phone_number: user1.phone_number_formatted)
      expect_sms_enqueued(phone_number: user2.phone_number_formatted)

      perform_enqueued_jobs # send emails so we can observe them
      expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array([user1.email, user2.email])
    end

    it "outputs the tokens" do
      allow(Devise.token_generator).to receive(:generate).and_return("t0k3n")
      expect(subject).to eq({ user1.id => "t0k3n", user2.id => "t0k3n" })
    end
  end

  context "starts today or tomorrow" do
    let(:starts_at_initial) { 2.hours.from_now }

    it "triggers sending mails to both user and agents (except the one who initiated the change)" do
      # expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user1, token: token1 })
      # expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user2, token: token2 })
      # expect(Agents::RdvMailer).not_to receive(:with).with({ rdv: rdv, agent: agent1, author: agent1 })
      # expect(Agents::RdvMailer).to receive(:with).with({ rdv: rdv, agent: agent2, author: agent1 })

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
