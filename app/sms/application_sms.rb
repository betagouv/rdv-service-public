# Similar to ActionMailer::Base, but for sms.
# Prepare the Sms to be sent and schedule a job with SmsSender.
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
  attr_accessor :receipt_params

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
        sms.receipt_params[:event] = symbol
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

  def deliver_later(...)
    raise "not implemented"
  end
end
