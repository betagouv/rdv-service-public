require "redis"

module Rdv::UsingWaitingRoom
  extend ActiveSupport::Concern

  REDIS_WAITING_ROOM_KEY = "#{Rails.env}:user_in_waiting_room_rdv_id".freeze

  def user_in_waiting_room?
    Redis.with_connection do |redis|
      status == "unknown" && redis.lpos(REDIS_WAITING_ROOM_KEY, id).present?
    end
  end

  def set_user_in_waiting_room!
    Redis.with_connection do |redis|
      redis.lpush(REDIS_WAITING_ROOM_KEY, id)
    end
  end

  class_methods do
    def reset_user_in_waiting_room!
      Redis.with_connection do |redis|
        redis.del(REDIS_WAITING_ROOM_KEY)
      end
    end
  end
end
