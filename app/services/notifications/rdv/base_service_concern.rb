module Notifications::Rdv::BaseServiceConcern
  extend ActiveSupport::Concern

  def initialize(rdv)
    @rdv = rdv
  end

  def perform
    return false if @rdv.starts_at < Time.zone.now || !@rdv.motif.visible_and_notified?

    if methods.include?(:notify_user_by_mail)
      users_to_notify
        .select(&:notifiable_by_email?)
        .each { notify_user_by_mail(_1) }
    end

    if methods.include?(:notify_user_by_sms)
      users_to_notify
        .select(&:notifiable_by_sms?)
        .each { notify_user_by_sms(_1) }
    end

    if methods.include?(:notify_agent)
      @rdv.agents.each { notify_agent(_1) }
    end

    true
  end

  def users_to_notify
    @rdv.users.map(&:user_to_notify).uniq
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
