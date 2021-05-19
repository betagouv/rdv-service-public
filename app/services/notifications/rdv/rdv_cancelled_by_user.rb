# frozen_string_literal: true

class Notifications::Rdv::RdvCancelledByUser < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_user_by_mail(user)
    Users::RdvMailer.rdv_cancelled_by_user(@rdv, user).deliver_later
    @rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: :cancelled_by_user)
  end
end
