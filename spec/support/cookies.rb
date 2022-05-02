# frozen_string_literal: true

# Needed to test signed and encrypted cookies: https://collectiveidea.com/blog/archives/2012/01/05/capybara-cucumber-and-how-the-cookie-crumbles
module Capybara
  class Session
    def cookies
      @cookies ||= ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
    end
  end
end
