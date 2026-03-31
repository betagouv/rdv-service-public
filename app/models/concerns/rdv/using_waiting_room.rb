require "redis"

module Rdv::UsingWaitingRoom
  extend ActiveSupport::Concern

  REDIS_WAITING_ROOM_KEY = "#{Rails.env}:users_in_waiting_room".freeze

  def user_in_waiting_room?
    return false unless status == "unknown"

    Redis.with_connection do |redis|
      redis.sismember(REDIS_WAITING_ROOM_KEY, id)
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    false
  end

  def set_user_in_waiting_room!
    Redis.with_connection do |redis|
      redis.sadd?(REDIS_WAITING_ROOM_KEY, id)
    end

    agent_ids_from_db.each do |agent_id|
      AgendaChannel.broadcast_to(agent_id, model: "Rdv", refresh_periods: [[starts_at, ends_at]])
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
