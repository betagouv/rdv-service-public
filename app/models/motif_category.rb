# frozen_string_literal: true

class MotifCategory < ApplicationRecord
  # Relations
  has_many :motifs, dependent: :nullify
  has_and_belongs_to_many :territories

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :short_name, presence: true, uniqueness: true
end
