class UserLoginCode
  EXPIRES_IN = 30.minutes

  def self.code_for(email)
    Redis.with_connection { |redis| redis.get(cache_key_for(email)) }
  end

  def self.store_new_code_for(email)
    code = SecureRandom.random_number(100_000..999_999).to_s
    Redis.with_connection { |redis| redis.set(cache_key_for(email), code, ex: EXPIRES_IN) }
    code
  end

  def self.cache_key_for(email)
    "user_login_code_#{email}"
  end
end
