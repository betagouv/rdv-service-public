class AgentTerritorialAccessRight < ApplicationRecord
  # Mixins
  has_paper_trail

  # Relations
  belongs_to :agent
  belongs_to :territory

  # Hooks
  before_destroy :prevent_removing_last_territory_admin, if: :territory_admin?
  before_save :prevent_removing_last_territory_admin, if: :losing_territory_admin?

  scope :without_any_rights_allowed, lambda {
    where(
      territory_admin: false,
      allow_to_manage_teams: false,
      allow_to_manage_access_rights: false,
      allow_to_invite_agents: false
    )
  }
  scope :with_some_rights_allowed, -> { without_any_rights_allowed.invert_where }

  private

  def losing_territory_admin?
    territory_admin_was && !territory_admin
  end

  def prevent_removing_last_territory_admin
    return if territory.agent_territorial_access_rights.where(territory_admin: true).where.not(id: id).exists?

    errors.add(:base, "Il doit toujours y avoir au moins un agent responsable par espace")
    throw :abort
  end
end
