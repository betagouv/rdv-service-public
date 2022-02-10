# frozen_string_literal: true

class Team < ApplicationRecord
  # Mixins
  include TextSearch
  def self.search_keys = %i[name]

  # Attributes
  auto_strip_attributes :name

  # Relations
  belongs_to :territory
  has_many :agent_teams, dependent: :destroy

  # Through relations
  has_many :agents, through: :agent_teams

  # Validations
  validates :name, presence: true, uniqueness: { scope: :territory }
  validate :agent_from_same_territory, if: -> { agents.any? }

  ## -

  def to_s
    name
  end

  private

  def agent_from_same_territory
    return if agents.flat_map(&:organisations).flat_map(&:territory).uniq.count == 1

    errors.add(:agents, :not_from_same_territory)
  end
end
