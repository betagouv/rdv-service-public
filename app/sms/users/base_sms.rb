# Base class for all Sms sent to Users
class Users::BaseSms < ApplicationSms
  def initialize(rdv, user, token)
    super
    @rdv = rdv
    @user = user
    @token = token

    @receipt_params[:rdv] = rdv
    @receipt_params[:user] = user
  end

  attr_reader :content

  def deliver_later(queue: :sms, priority: 0)
    SmsJob.set(queue: queue, priority: priority).perform_later(
      sender_name: @rdv.domain.sms_sender_name,
      phone_number: @user.phone_number_formatted,
      content: content,
      territory_id: @rdv.territory.id,
      receipt_params: @receipt_params
    )
  end

  private

  def domain_host
    @rdv.domain.host_name
  end
end
