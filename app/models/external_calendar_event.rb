class ExternalCalendarEvent < ApplicationRecord
  belongs_to :agent

  scope :within_range, ->(range) { where("starts_at < ? AND ends_at > ?", range.end, range.begin) }
end
