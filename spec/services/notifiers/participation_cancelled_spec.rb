RSpec.describe Notifiers::ParticipationCancelled, type: :service do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let(:now) { Time.zone.parse("2025-07-30 09:00") }

  before { travel_to now }

  def expect_mail_deliver_later(mailer_class, mailer_method, **params)
    mailer_double = instance_double(mailer_class)
    allow(mailer_class).to receive(:with).with(**params)
      .and_return(mailer_double)
    mail_double = double
    allow(mailer_double).to receive(mailer_method).and_return(mail_double)
    expect(mail_double).to receive(:deliver_later)
  end

  def expect_sms_deliver_later(sms_class, sms_method, *, **)
    sms_double = double
    allow(sms_class).to receive(sms_method).with(*, **).and_return(sms_double)
    expect(sms_double).to receive(:deliver_later)
  end

  context "participation à un RDV collectif annulée par l’agent du RDV" do
    let!(:motif) { create(:motif, collectif: true, organisation:) }
    let!(:user) { create(:user, organisations: [organisation]) }
    let!(:rdv) { create(:rdv, :collectif, :without_users, starts_at: now + 3.days, motif:, organisation:, agents: [agent]) }
    let!(:participation) { create(:participation, rdv:, user:) }

    specify do
      expect_mail_deliver_later(Users::RdvMailer, :participation_cancelled, rdv:, user:, token: instance_of(String), participation:)
      expect_mail_deliver_later(Agents::RdvMailer, :participation_cancelled, participation:, agent:, author: agent)
      expect_sms_deliver_later(Users::RdvSms, :participation_cancelled, rdv, user, participation.restricted_auth_token)
      described_class.perform_with(participation:, author: agent)
    end
  end

  context "participation à un RDV collectif annulée par un autre agent" do
    let!(:motif) { create(:motif, collectif: true, organisation:) }
    let!(:user) { create(:user, organisations: [organisation]) }
    let!(:rdv) { create(:rdv, :collectif, :without_users, starts_at: now + 3.days, motif:, organisation:, agents: [agent]) }
    let!(:participation) { create(:participation, rdv:, user:) }
    let(:other_agent) { create(:agent, organisations: [organisation]) }

    specify do
      expect_mail_deliver_later(Users::RdvMailer, :participation_cancelled, rdv:, user:, token: instance_of(String), participation:)
      expect_mail_deliver_later(Agents::RdvMailer, :participation_cancelled, participation:, agent:, author: other_agent)
      expect_sms_deliver_later(Users::RdvSms, :participation_cancelled, rdv, user, participation.restricted_auth_token)
      described_class.perform_with(participation:, author: other_agent)
    end
  end
end
