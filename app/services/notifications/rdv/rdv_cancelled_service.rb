# frozen_string_literal: true

class Notifications::Rdv::RdvCancelledService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_agent(agent)
    Agents::RdvMailer.rdv_cancelled(@rdv.payload(:destroy), agent, @author).deliver_later
  end

  def notify_user_by_mail(user)
    # Only send sms for excused cancellations (not for no-show)
    return unless @rdv.status == "excused"

    Users::RdvMailer.rdv_cancelled(@rdv.payload(:destroy, user), user, @author).deliver_later

    event_name = @author.is_a?(Agent) ? :cancelled_by_agent : :cancelled_by_user
    @rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: event_name)
  end

  def notify_user_by_sms(user)
    # Only send sms for excused cancellations by an Agent (not for no-show, not for self-cancellation)
    return unless @author.is_a? Agent
    return unless @rdv.status == "excused"

    SendTransactionalSmsJob.perform_later(:rdv_cancelled, @rdv.id, user.id)
    @rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: :cancelled_by_agent)
  end
end
