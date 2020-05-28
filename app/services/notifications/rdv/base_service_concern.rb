module Notifications::Rdv::BaseServiceConcern
  extend ActiveSupport::Concern

  def initialize(rdv)
    @rdv = rdv
  end

  def perform
    return false if @rdv.starts_at < Time.zone.now || @rdv.motif.disable_notifications_for_users

    if methods.include?(:notify_user)
      @rdv.users.map(&:reload).map(&:user_to_notify).uniq.each { notify_user(_1) }
    end

    if methods.include?(:notify_agent)
      @rdv.agents.each { notify_agent(_1) }
    end

    true
  end
end
