class AgentTerritorialAccessRight < ApplicationRecord
  # Mixins
  has_paper_trail

  # Relations
  belongs_to :agent
  belongs_to :territory

  # Hooks
  before_destroy :prevent_removing_last_full_rights_admin, if: :full_rights?
  before_save :prevent_removing_last_full_rights_admin, if: :losing_full_rights?

  scope :without_any_rights_allowed, lambda {
    where(
      full_rights: false,
      allow_to_manage_teams: false,
      allow_to_manage_access_rights: false,
      allow_to_invite_agents: false
    )
  }
  scope :with_some_rights_allowed, -> { without_any_rights_allowed.invert_where }

  private

  def losing_full_rights?
    full_rights_was && !full_rights
  end

  def prevent_removing_last_full_rights_admin
    return if territory.agent_territorial_access_rights.where(full_rights: true).where.not(id: id).exists?

    errors.add(:base, "Il doit toujours y avoir au moins un agent responsable par espace")
    throw :abort
  end
end
