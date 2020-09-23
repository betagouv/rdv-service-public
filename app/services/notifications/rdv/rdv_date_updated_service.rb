class Notifications::Rdv::RdvDateUpdatedService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  # TODO: it's weird that it uses the exact same notifications as for creations

  def notify_user_by_mail(user)
    Users::RdvMailer.rdv_created(@rdv, user).deliver_later
    @rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: :updated)
  end

  def notify_user_by_sms(user)
    SendTransactionalSmsJob.perform_later(:rdv_created, @rdv.id, user.id)
    @rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: :updated)
  end

  def notify_agent(agent)
    return false if \
      change_triggered_by?(agent) ||
      ![Date.today, Date.tomorrow].include?(@rdv.starts_at_before_last_save.to_date)

    Agents::RdvMailer.rdv_starting_soon_date_updated(
      @rdv,
      agent,
      change_triggered_by_str,
      @rdv.starts_at_before_last_save
    ).deliver_later
  end
end
