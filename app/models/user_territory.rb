# frozen_string_literal: true

class UserTerritory < ApplicationRecord
  belongs_to :user
  belongs_to :territory
end
