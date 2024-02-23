class Export < ApplicationRecord
  belongs_to :agent

  scope :not_expired, -> { where("expires_at > ?", Time.zone.now) }
  scope :available, -> { not_expired.where.not(content: nil) }

  after_create { CleanupExportJob.set(wait_until: expires_at).perform_later(id) }
end
