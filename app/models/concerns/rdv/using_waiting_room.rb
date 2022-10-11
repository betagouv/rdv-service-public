# frozen_string_literal: true

require "redis"

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379")
REDIS = Redis.new(url: redis_url)

module Rdv::UsingWaitingRoom
  extend ActiveSupport::Concern

  def user_in_waiting_room?
    status == "unknown" && REDIS.get("#{Rails.env}:user_in_waiting_room_rdv_id:#{id}").to_bool
  end

  def set_user_in_waiting_room!
    REDIS.set("#{Rails.env}:user_in_waiting_room_rdv_id:#{id}", true)
  end

  class_methods do
    def reset_user_in_waiting_room!
      REDIS.del(REDIS.keys("#{Rails.env}:user_in_waiting_room_rdv_id:*"))
    end
  end
end
