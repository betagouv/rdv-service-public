# frozen_string_literal: true

require "openssl"

class CustomDeviseTokenGenerator < Devise::TokenGenerator
  def generate(klass, column)
    klass.in?([User, RdvsUser]) && column == :invitation_token ? generate_short_token : super
  end

  def generate_short_token
    key = key_for(:invitation_token)

    loop do
      raw = SecureRandom.send(:choose, [*"A".."Z", *"0".."9"], 8)
      enc = OpenSSL::HMAC.hexdigest(@digest, key, raw)
      break [raw, enc] unless User.where(invitation_token: enc).size.positive?
    end
  end
end
