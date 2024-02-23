class Export < ApplicationRecord
  # Attributes
  encrypts :content

  # Relations
  belongs_to :agent

  # Hooks
  after_create { CleanupExportJob.set(wait_until: expires_at).perform_later(id) }

  # Scopes
  scope :not_expired, -> { where("expires_at > ?", Time.zone.now) }
  scope :available, -> { not_expired.where.not(content: nil) }
end
