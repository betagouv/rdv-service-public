# frozen_string_literal: true

class Notifications::Rdv::RdvCreatedService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_user_by_mail(user)
    Users::RdvMailer.rdv_created(@rdv.payload(:create, user), user).deliver_later
    @rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: :created)
  end

  def notify_user_by_sms(user)
    Users::RdvSms.rdv_created(@rdv, user).deliver_later
    @rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: :created)
  end

  def notify_agent(agent)
    Agents::RdvMailer.rdv_created(@rdv.payload(:create, agent), agent).deliver_later
  end
end
