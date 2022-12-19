# frozen_string_literal: true

ACTIONS = %i[rdv_created rdv_cancelled rdv_updated rdv_upcoming_reminder].freeze

def expect_performed_notifications_for(agent, user, event)
  perform_enqueued_jobs
  expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(agent.email, user.email)
  expect(Receipt.where(user_id: user.id, channel: "sms", result: "delivered").count).to eq 1
  expect(Receipt.where(user_id: user.id, channel: "sms", event: event).count).to eq 1
end

def expect_notifiers_instance(rdv, agent, users, action)
  expect("Notifiers::#{action.to_s.camelize}".safe_constantize).to receive(:new).with(rdv, agent).and_call_original
  users.each do |user|
    expect(Users::RdvSms).to receive(action).with(rdv, user, /^[A-Z0-9]{8}$/).and_call_original.at_least(1)
    expect(Users::RdvMailer).to receive(:with).with({ rdv: rdv, user: user, token: /^[A-Z0-9]{8}$/ }).and_call_original.at_least(1)
  end
end

RSpec::Matchers.define :enqueued_notifications_for_agent? do |rdv, agent, action|
  match do |actual|
    expect(actual).to have_enqueued_mail(Agents::RdvMailer, action).with({ params: { rdv: rdv, agent: agent, author: agent }, args: [] })
    ACTIONS.reject { |i| i == action }.each do |other_action|
      expect(actual).not_to have_enqueued_mail(Agents::RdvMailer, other_action).with({ params: { rdv: rdv, agent: agent, author: agent }, args: [] })
    end
  end
  supports_block_expectations
end

RSpec::Matchers.define :enqueued_notifications_for_user? do |rdv, user, action|
  match do |actual|
    expect(actual).to have_enqueued_mail(Users::RdvMailer, action).with({ params: { rdv: rdv, user: user, token: /^[A-Z0-9]{8}$/ }, args: [] })
      .and have_enqueued_job(SmsJob).with(hash_including(phone_number: user.phone_number_formatted))
    ACTIONS.reject { |i| i == action }.each do |other_action|
      expect(actual).not_to have_enqueued_mail(Users::RdvMailer, other_action).with({ params: { rdv: rdv, user: user, token: /^[A-Z0-9]{8}$/ }, args: [] })
    end
  end
  supports_block_expectations
end

RSpec::Matchers.define_negated_matcher :not_enqueued_notifications_for_user?, :enqueued_notifications_for_user?
RSpec::Matchers.define_negated_matcher :not_enqueued_notifications_for_agent?, :enqueued_notifications_for_agent?
