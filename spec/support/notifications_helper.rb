# frozen_string_literal: true

module NotificationsHelper
  EVENTS = %w[rdv_created rdv_cancelled rdv_updated rdv_upcoming_reminder].freeze

  def relative_date(date, fallback_format = :short)
    return if date.nil?

    date = date.to_date
    if date == Date.current
      I18n.t "date.helpers.today"
    elsif date == Date.current + 1
      I18n.t "date.helpers.tomorrow"
    else
      I18n.l(date, format: fallback_format)
    end
  end

  def expect_performed_notifications_for(rdv, person, event)
    perform_enqueued_jobs
    klass = person.class

    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(person.email)

    if klass == User
      expect(Receipt.where(user_id: person.id, channel: "sms", result: "delivered").count).to eq 1

      expect(email_sent_to(person.email).subject).to include(email_title_for_user(rdv, event))
      expect(Receipt.where(user_id: person.id, channel: "sms", event: event).count).to eq 1
    elsif klass == Agent
      expect(email_sent_to(person.email).subject).to include(email_title_for_agent(rdv, person, event))
    end

    expect_no_other_performed_notifications_for(rdv, person, event)
  end

  def expect_no_other_performed_notifications_for(rdv, person, event)
    perform_enqueued_jobs
    klass = person.class
    other_events = EVENTS.reject { |i| i == event }

    if klass == User
      other_events.each do |other_event|
        expect(Receipt.where(user_id: person.id, channel: "sms", event: other_event).count).not_to eq 1
        expect(email_sent_to(person.email).subject).not_to include(email_title_for_user(rdv, other_event))
      end
    elsif klass == Agent
      other_events.reject { |i| i == "rdv_upcoming_reminder" }.each do |other_event|
        expect(email_sent_to(person.email).subject).not_to include(email_title_for_agent(rdv, person, other_event))
      end
    end
  end

  def email_title_for_agent(rdv, person, event)
    case event
    when "rdv_created"
      I18n.t("agents.rdv_mailer.rdv_created.title", domain_name: person.domain.name, date: relative_date(rdv.starts_at))
    when "rdv_cancelled"
      I18n.t("agents.rdv_mailer.rdv_cancelled.title", date: relative_date(rdv.starts_at))
    when "rdv_updated"
      I18n.t("agents.rdv_mailer.rdv_updated.title", date: relative_date(rdv.starts_at))
    end
  end

  def email_title_for_user(rdv, event)
    case event
    when "rdv_created"
      I18n.t("users.rdv_mailer.rdv_created.title", date: I18n.l(rdv.starts_at, format: :human))
    when "rdv_cancelled"
      I18n.t("users.rdv_mailer.rdv_cancelled.title", date: I18n.l(rdv.starts_at, format: :human), organisation: rdv.organisation.name)
    when "rdv_updated"
      I18n.t("users.rdv_mailer.rdv_updated.title", date: I18n.l(rdv.starts_at, format: :human))
    when "rdv_upcoming_reminder"
      I18n.t("users.rdv_mailer.rdv_upcoming_reminder.title", date: I18n.l(rdv.starts_at, format: :human))
    end
  end
end
