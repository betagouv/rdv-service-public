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
    Agents::RdvMailer.rdv_date_updated(
      @rdv,
      agent,
      @author,
      @rdv.attribute_before_last_save(:starts_at)
    ).deliver_later
  end
end
