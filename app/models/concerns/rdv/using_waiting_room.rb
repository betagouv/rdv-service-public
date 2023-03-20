# frozen_string_literal: true

require "redis"

module Rdv::UsingWaitingRoom
  extend ActiveSupport::Concern

  REDIS_FOR_WAITING_ROOMS = Redis.new(url: Rails.configuration.x.redis_url)
  REDIS_WAITING_ROOM_KEY = "#{Rails.env}:user_in_waiting_room_rdv_id".freeze

  def user_in_waiting_room?
    status == "unknown" && REDIS_FOR_WAITING_ROOMS.lpos(REDIS_WAITING_ROOM_KEY, id).present?
  end

  def set_user_in_waiting_room!
    REDIS_FOR_WAITING_ROOMS.lpush(REDIS_WAITING_ROOM_KEY, id)
    REDIS_FOR_WAITING_ROOMS.expire(REDIS_FOR_WAITING_ROOMS, 24.hours)
  end

  class_methods do
    def reset_user_in_waiting_room!
      REDIS_FOR_WAITING_ROOMS.del(REDIS_WAITING_ROOM_KEY)
    end
  end
end
