require "icalendar"
require "icalendar/tzinfo"

module Admin::Ics
  TZID = "Europe/Paris".freeze

  def self.status_from_action(action)
    return "CANCELLED" if action == :destroy

    "CONFIRMED"
  end
end
