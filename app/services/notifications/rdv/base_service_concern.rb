module Notifications::Rdv::BaseServiceConcern
  extend ActiveSupport::Concern

  def initialize(rdv)
    @rdv = rdv
  end

  def perform
    return false if @rdv.starts_at < Time.zone.now || @rdv.motif.disable_notifications_for_users

    if methods.include?(:notify_user_by_mail)
      users_to_notify.select { _1.email.present? }.each { notify_user_by_mail(_1) }
    end

    if methods.include?(:notify_user_by_sms)
      users_to_notify.select { _1.phone_number_formatted.present? }.each { notify_user_by_sms(_1) }
    end

    if methods.include?(:notify_agent)
      @rdv.agents.each { notify_agent(_1) }
    end

    true
  end

  def users_to_notify
    @rdv.users.map(&:user_to_notify).uniq
  end
end
