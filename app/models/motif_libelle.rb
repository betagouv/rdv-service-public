# frozen_string_literal: true

class MotifLibelle < ApplicationRecord
  auto_strip_attributes :name

  belongs_to :service

  default_scope { order("LOWER(name)") }

  VISITE_PROCHE = "Visite d'un proche"
end
