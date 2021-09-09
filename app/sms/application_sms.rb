# frozen_string_literal: true

# Similar to ActionMailer::Base, but for sms.
# Prepare the Sms to be sent and schedule a DelayedJob with SmsSendingService.
#
# To be subclassed:
# class SomeSmsSubclass < ApplicationSms
#   def initialize(arg, other_arg)
#     ...
#   end
#   def some_message(arg, other_arg)
#     ....
#   end
# end
#
# Usage:
# SomeSmsSubclass.some_message(arg, other_arg).deliver_later
class ApplicationSms
  class InvalidMobilePhoneNumberError < StandardError; end

  # SMS attributes need to be set by the subclass, either in initialize or in the message method.
  attr_accessor :phone_number, :content, :tags, :provider, :key

  class << self
    def method_missing(symbol, *args)
      # This lets us call instance methods on the ApplicationSms subclass and send deliver_later to it.
      # e.g. FileAttenteMailer.new_creneau_available(rdv, user).deliver_later
      #
      # 1. instantiate a new sms with the passed params,
      # 2. forward it the message,
      # 3. return the sms
      #
      # Note: args are passed both to initialize and to the message method
      if public_instance_methods(true).include?(symbol)
        sms = new(*args)
        sms.public_send(symbol, *args)
        sms
      else
        super
      end
    end

    def respond_to_missing?(symbol, include_all = false)
      public_instance_methods(true).include?(symbol) || super
    end
  end

  # Enqueue a DelayedJob with the sms
  # Note: the stored parameter in the delayed_jobs table is the ApplicationSms instance.
  def deliver_later
    raise InvalidMobilePhoneNumberError, "#{phone_number} is not a valid mobile phone number" unless Phonelib.parse(phone_number).types.include?(:mobile)

    SmsSendingService.delay.perform_with(phone_number, content, tags, provider, key)
  end

  private

  # Make Rubymine happy: otherwise it would complain in method_missing when calling `new` with parameters.
  def initialize(*_args); end
end
