# frozen_string_literal: true

class MotifsPlageOuverture < ApplicationRecord
  belongs_to :motif
  belongs_to :plage_ouverture
end
