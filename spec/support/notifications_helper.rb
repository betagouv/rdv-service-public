# frozen_string_literal: true

module NotificationsHelper
  include DateHelper

  EVENTS = %i[rdv_created rdv_cancelled rdv_updated rdv_upcoming_reminder].freeze

  def expect_notifications_sent_for(rdv, person, event, notif_type = nil)
    perform_enqueued_jobs
    klass = person.class
    other_events = EVENTS.reject { |i| i == event }

    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(person.email)

    if klass == User
      expect_sms_sent_for(person, event) unless notif_type == :mail
      expect(email_sent_to(person.email).subject).to include(email_title_for_user(rdv, event))
      # Check for no notifications for undesirable events
      other_events.each { expect_no_notifications_for(rdv, person, _1) }
    elsif klass == Agent
      expect(email_sent_to(person.email).subject).to include(email_title_for_agent(rdv, person, event))
      # Check for no notifications for undesirable events
      # We reject rdv_upcoming_reminder event because it is not used for agents
      other_events.reject { |i| i == :rdv_upcoming_reminder }.each { expect_no_notifications_for(rdv, person, _1) }
    end
  end

  def expect_sms_sent_for(person, event)
    perform_enqueued_jobs
    expect(Receipt.where(user_id: person.id, channel: "sms", result: "delivered").count).to eq 1
    expect(Receipt.where(user_id: person.id, channel: "sms", event: event).count).to eq 1
  end

  def expect_no_notifications_for(rdv, person, event)
    perform_enqueued_jobs
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

  def expect_no_notifications_for_user(user = nil)
    perform_enqueued_jobs

    expect(ActionMailer::Base.deliveries.size).to eq(0)

    if user
      expect(Receipt.where(user_id: user.id, channel: "sms", result: "delivered").count).to eq 0
    end
  end

  def email_title_for_agent(rdv, person, event)
    case event
    when :rdv_created
      if rdv.collectif?
        I18n.t("agents.rdv_mailer.rdv_created.title_participation", domain_name: person.domain.name, date: relative_date(rdv.starts_at))
      else
        I18n.t("agents.rdv_mailer.rdv_created.title", domain_name: person.domain.name, date: relative_date(rdv.starts_at))
      end
    when :rdv_cancelled
      if rdv.collectif?
        I18n.t("agents.rdv_mailer.rdv_cancelled.title_participation", date: relative_date(rdv.starts_at))
      else
        I18n.t("agents.rdv_mailer.rdv_cancelled.title", date: relative_date(rdv.starts_at))
      end
    when :rdv_updated
      # Maybe not enough precision here (because specific design choice), the date used for agents rdv update is the previsous date of the rdv
      "modifié"
    end
  end

  def email_title_for_user(rdv, event)
    case event
    when :rdv_created
      I18n.t("users.rdv_mailer.rdv_created.title", date: I18n.l(rdv.starts_at, format: :human))
    when :rdv_cancelled
      I18n.t("users.rdv_mailer.rdv_cancelled.title", date: I18n.l(rdv.starts_at, format: :human), organisation: rdv.organisation.name)
    when :rdv_updated
      I18n.t("users.rdv_mailer.rdv_updated.title", date: I18n.l(rdv.starts_at, format: :human))
    when :rdv_upcoming_reminder
      I18n.t("users.rdv_mailer.rdv_upcoming_reminder.title", date: I18n.l(rdv.starts_at, format: :human))
    end
  end
end
