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

  def expect_performed_notifications_for(rdv, person, event, notif_type = nil)
    perform_enqueued_jobs
    klass = person.class
    other_events = EVENTS.reject { |i| i == event }

    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(person.email)

    if klass == User
      expect_performed_sms_for(person, event) unless notif_type == "mail"
      expect(email_sent_to(person.email).subject).to include(email_title_for_user(rdv, event))
      other_events.each { dont_expect_performed_notifications_for(rdv, person, _1) }
    elsif klass == Agent
      expect(email_sent_to(person.email).subject).to include(email_title_for_agent(rdv, person, event))
      other_events.reject { |i| i == "rdv_upcoming_reminder" }.each { dont_expect_performed_notifications_for(rdv, person, _1) }
    end
  end

  def expect_performed_sms_for(person, event)
    expect(Receipt.where(user_id: person.id, channel: "sms", result: "delivered").count).to eq 1
    expect(Receipt.where(user_id: person.id, channel: "sms", event: event).count).to eq 1
  end

  def dont_expect_performed_notifications_for(rdv, person, event)
    klass = person.class
    if klass == User
      expect(Receipt.where(user_id: person.id, channel: "sms", event: event).count).to eq 0
      if ActionMailer::Base.deliveries.map(&:to).flatten.include?(person.email)
        expect(email_sent_to(person.email).subject).not_to include(email_title_for_user(rdv, event))
      end
    elsif klass == Agent
      if ActionMailer::Base.deliveries.map(&:to).flatten.include?(person.email)
        expect(email_sent_to(person.email).subject).not_to include(email_title_for_agent(rdv, person, event))
      end
    end
  end

  def dont_expect_any_performed_notifications(user = nil)
    perform_enqueued_jobs

    expect(ActionMailer::Base.deliveries.size).to eq(0)

    if user
      expect(Receipt.where(user_id: user.id, channel: "sms", result: "delivered").count).to eq 0
    end
  end

  def email_title_for_agent(rdv, person, event)
    case event
      # virer le relative_date
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
