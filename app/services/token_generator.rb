# frozen_string_literal: true

class TokenGenerator < BaseService
  def initialize(key)
    @key = key
  end

  def perform
    generate_token
  end

  private

  def generate_token
    raw = SecureRandom.send(:choose, [*"A".."Z", *"0".."9"], 8)
    enc = OpenSSL::HMAC.hexdigest("SHA256", @key, raw)
    [raw, enc]
  end
end
