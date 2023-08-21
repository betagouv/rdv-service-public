# frozen_string_literal: true

module AgentRole::IntervenantRoleChangeable
  extend ActiveSupport::Concern

  def change_role_to_intervenant
    assign_role_from_agent && agent.save
  end

  private

  def assign_role_from_agent
    # A cause des nested attributes nous devons passer par l'agent pour assigner le role car celui ci a des validations contextuels liées aux roles intervenants
    # Sans cela, en sauvegardant l'agent_role simplement, l'agent n'est pas valide car il n'a pas de mail et un role qui n'est pas encore intervenant.
    agent.roles = [self]
  end

end
