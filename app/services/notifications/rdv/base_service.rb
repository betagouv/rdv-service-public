class Notifications::Rdv::BaseService < ::BaseService
  def initialize(rdv)
    @rdv = rdv
  end

  def perform
    return false if @rdv.starts_at < Time.zone.now || @rdv.motif.disable_notifications_for_users

    @rdv.users.map(&:user_to_notify).uniq.each { notify_user(_1) }
    @rdv.agents.each { notify_agent(_1) }
    true
  end

  protected

  def notify_user(_user); end

  def notify_agent(_agent); end
end
