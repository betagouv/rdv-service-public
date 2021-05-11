# frozen_string_literal: true

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
    return if change_triggered_by?(agent)
    return unless soon_date?(@rdv.starts_at) || soon_date?(@rdv.starts_at_before_last_save)

    Agents::RdvMailer.rdv_starting_soon_date_updated(
      @rdv,
      agent,
      change_triggered_by_str).deliver_later
  end
end
