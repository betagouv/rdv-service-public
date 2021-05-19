# frozen_string_literal: true

require "icalendar"
require "icalendar/tzinfo"

module Admin::Ics
  TZID = "Europe/Paris"

  def self.status_from_action(action)
    return "CANCELLED" if action == :destroy

    "CONFIRMED"
  end
end
