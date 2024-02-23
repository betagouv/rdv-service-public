class Export < ApplicationRecord
  belongs_to :agent

  scope :not_expired, -> { where("expires_at > ?", Time.zone.now) }
  scope :available, -> { not_expired.where.not(content: nil) }
end
