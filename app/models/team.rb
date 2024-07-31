class Team < ApplicationRecord
  # Mixins
  has_paper_trail(
    only: %i[name agent_ids],
    meta: { virtual_attributes: :virtual_attributes_for_paper_trail }
  )

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

  # Scopes
  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(teams.name))")) }

  ## -

  def to_s
    name
  end

  def virtual_attributes_for_paper_trail
    {
      agent_ids: agents.ids,
    }
  end

  private

  def agent_from_same_territory
    return if agents.flat_map(&:organisations).flat_map(&:territory).uniq.count == 1

    errors.add(:agents, :not_from_same_territory)
  end
end
