class Notifications::Rdv::RdvCreatedService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_user_by_mail(user)
    Users::RdvMailer.rdv_created(@rdv, user).deliver_later
    @rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: :created)
  end

  def notify_user_by_sms(user)
    SendTransactionalSmsJob.perform_later(:rdv_created, @rdv.id, user.id)
    @rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: :created)
  end

  def notify_agent(agent)
    return false unless [Date.today, Date.tomorrow].include?(@rdv.starts_at.to_date)

    Agents::RdvMailer.rdv_starting_soon_created(@rdv, agent).deliver_later
  end
end
