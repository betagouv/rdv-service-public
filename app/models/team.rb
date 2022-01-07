# frozen_string_literal: true

class Team < ApplicationRecord
  include PgSearch::Model

  pg_search_scope(:search_by_text,
                  against: :name,
                  using: { tsearch: { prefix: true, any_word: true } })

  auto_strip_attributes :name

  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(teams.name))")) }

  belongs_to :territory

  has_many :agent_teams, dependent: :destroy
  has_many :agents, through: :agent_teams

  validates :name, presence: true, uniqueness: true
  validate :agent_from_same_territory, if: -> { agents.any? }

  def to_s
    name
  end

  private

  def agent_from_same_territory
    return if agents.flat_map(&:territories).uniq.count == 1

    errors.add(:agents, :not_from_same_territory)
  end
end
