class ExternalCalendarSyncExecutionsLog < ApplicationRecord
  # Relations
  belongs_to :external_calendar_sync_execution

  # Validations
  validates :message, presence: true
  validates :emitted_at, presence: true
end
