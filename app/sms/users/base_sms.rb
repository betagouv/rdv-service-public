# Base class for all Sms sent to Users
class Users::BaseSms < ApplicationSms
  def initialize(rdv, user)
    super
    @rdv = rdv
    @user = user

    participation = rdv.participations.find do |participation|
      participation.user.user_to_notify == user
    end

    @restricted_auth_token = participation.restricted_auth_token

    @receipt_params[:rdv] = rdv
    @receipt_params[:user] = user
  end

  attr_reader :content

  def deliver_later(queue: :latency_30s)
    SmsJob.set(queue: queue).perform_later(
      sender_name: @rdv.domain.sms_sender_name,
      phone_number: @user.phone_number_formatted,
      content: content,
      territory_id: @rdv.territory.id,
      receipt_params: @receipt_params
    )
  end

  private

  attr_reader :restricted_auth_token

  def domain_host
    @rdv.domain.host_name
  end
end
