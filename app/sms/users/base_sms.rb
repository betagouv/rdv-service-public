# frozen_string_literal: true

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

  # Enqueue a DelayedJob with the sms
  # Note: the stored parameter in the delayed_jobs table is the ApplicationSms instance.
  def deliver_later(queue: :sms)
    SmsJob.perform_later(
      queue,
      sender_name: @rdv.domain.sms_sender_name,
      phone_number: @user.phone_number_formatted,
      content: @content,
      tags: tags,
      provider: @rdv.organisation&.territory&.sms_provider,
      key: @rdv.organisation&.territory&.sms_configuration,
      receipt_params: @receipt_params
    )
  end

  private

  def tags
    [
      ENV["APP"]&.gsub("-rdv-solidarites", ""), # shorter names
      "dpt-#{@rdv.organisation&.departement_number}",
      "org-#{@rdv.organisation&.id}",
      self.class.name.demodulize.underscore,
    ].compact
  end

  def domain_host
    @rdv.domain.dns_domain_name
  end
end
