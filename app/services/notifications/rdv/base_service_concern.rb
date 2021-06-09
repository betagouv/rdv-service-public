# frozen_string_literal: true

module Notifications::Rdv::BaseServiceConcern
  extend ActiveSupport::Concern
  include DateHelper

  def initialize(rdv)
    @rdv = rdv
  end

  def perform
    return if @rdv.starts_at < Time.zone.now

    notify_users_by_mail
    notify_users_by_sms
    notify_agents
  end

  private

  def notify_users_by_mail
    return unless @rdv.motif.visible_and_notified?
    return unless methods.include?(:notify_user_by_mail)

    users_to_notify
      .select(&:notifiable_by_email?)
      .each { notify_user_by_mail(_1) }
  end

  def notify_users_by_sms
    return unless @rdv.motif.visible_and_notified?
    return unless methods.include?(:notify_user_by_sms)

    users_to_notify
      .select(&:notifiable_by_sms?)
      .each { notify_user_by_sms(_1) }
  end

  def notify_agents
    return unless methods.include?(:notify_agent)

    @rdv.agents
      .select { should_notify_agent(_1) }
      .each { notify_agent(_1) }
  end

  def users_to_notify
    @rdv.users.map(&:user_to_notify).uniq
  end

  def should_notify_agent(agent)
    level = agent.rdv_notifications_level
    return true if level == "all"
    return false if level == "none"
    return false if change_triggered_by?(agent)
    return false if level == "soon" && !soon_date?(@rdv.starts_at) && !soon_date?(@rdv.attribute_before_last_save(:starts_at))

    true
  end

  protected

  def change_triggered_by?(user_or_agent)
    change_triggered_by_str == user_or_agent.name_for_paper_trail
  end

  def change_triggered_by_str
    # TODO: this is quite hacky as it relies on the last version being
    # the one that triggered the notification
    @rdv.versions.last.whodunnit
  end
end
