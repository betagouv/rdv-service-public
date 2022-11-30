# frozen_string_literal: true

class ReferentAssignation < ApplicationRecord
  include WebhookDeliverable

  belongs_to :user
  belongs_to :agent

  has_many :organisations, through: :user
  has_many :webhook_endpoints, through: :organisations

  validates :user_id, uniqueness: { scope: :agent }
end
