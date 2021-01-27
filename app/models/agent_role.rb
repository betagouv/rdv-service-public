class AgentRole < ApplicationRecord
  LEVEL_BASIC = "basic".freeze
  LEVEL_ADMIN = "admin".freeze
  LEVELS = [LEVEL_BASIC, LEVEL_ADMIN].freeze

  self.table_name = "agents_organisations"

  belongs_to :agent
  belongs_to :organisation

  validates :level, inclusion: { in: LEVELS }
  validates :agent, uniqueness: { scope: :organisation }

  scope :level_basic, -> { where(level: LEVEL_BASIC) }
  scope :level_admin, -> { where(level: LEVEL_ADMIN) }
  scope :in_departement, lambda { |dpt|
    joins(:organisation).where(organisations: { departement: dpt.to_s })
  }

  accepts_nested_attributes_for :agent

  def basic?
    level == LEVEL_BASIC
  end

  def admin?
    level == LEVEL_ADMIN
  end

  def can_access_others_planning?
    admin? || agent.service.secretariat?
  end
end
