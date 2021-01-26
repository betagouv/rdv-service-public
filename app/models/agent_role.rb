class AgentRole < ApplicationRecord
  LEVEL_BASIC = "basic".freeze
  LEVEL_ADMIN = "admin".freeze
  LEVELS = [LEVEL_BASIC, LEVEL_ADMIN].freeze

  self.table_name = "agents_organisations"

  belongs_to :agent
  belongs_to :organisation

  validates :level, inclusion: { in: LEVELS }

  scope :level_basic, -> { where(level: LEVEL_BASIC) }
  scope :level_admin, -> { where(level: LEVEL_ADMIN) }

  def basic?
    role == LEVEL_BASIC
  end

  def admin?
    role == LEVEL_ADMIN
  end
end
