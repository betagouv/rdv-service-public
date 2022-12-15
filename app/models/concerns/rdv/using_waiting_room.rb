# frozen_string_literal: true

require "redis"

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379")
REDIS = Redis.new(url: redis_url)

module Rdv::UsingWaitingRoom
  extend ActiveSupport::Concern

  REDIS_WAITING_ROOM_KEY = "#{Rails.env}:user_in_waiting_room_rdv_id".freeze

  def user_in_waiting_room?
    status == "unknown" && REDIS.lpos(REDIS_WAITING_ROOM_KEY, id).present?
  end

  def set_user_in_waiting_room!
    REDIS.lpush(REDIS_WAITING_ROOM_KEY, id)
  end

  class_methods do
    def reset_user_in_waiting_room!
      REDIS.del(REDIS_WAITING_ROOM_KEY)
    end
  end
end
