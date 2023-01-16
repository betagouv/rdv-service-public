# frozen_string_literal: true

module Motif::SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :active, lambda { |active = true|
      active ? where(deleted_at: nil) : where.not(deleted_at: nil)
    }
  end

  def soft_delete
    rdvs.any? ? update!(:deleted_at, Time.zone.now) : destroy
  end
end
