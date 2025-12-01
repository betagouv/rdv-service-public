module ApplicationCable
  class Channel < ActionCable::Channel::Base
    rescue_from(StandardError) { Sentry.capture_exception(_1) }
  end
end
