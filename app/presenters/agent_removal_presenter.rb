# frozen_string_literal: true

class AgentRemovalPresenter
  delegate :will_destroy?, to: :agent_removal_service
  attr_reader :agent, :organisation

  def initialize(agent, organisation)
    @agent = agent
    @organisation = organisation
  end

  def button_value
    if will_destroy?
      "Supprimer le compte"
    else
      "Retirer de l'organisation"
    end
  end

  def confirm_message
    if will_destroy?
      <<~STR
        Cet agent appartient uniquement à l'organisation #{organisation.name}. Vous vous apprêtez à retirer cet agent de cette organisation et à supprimer son compte définitivement.

        Toutes ses indisponibilités et ses plages d'ouvertures seront supprimées de manière irréversible.

        Suite à cette suppression vous pourrez éventuellement créer un nouveau compte pour l'agent et l'affecter à un service différent
      STR
    else
      <<~STR
        Voulez-vous vraiment retirer cet agent de l'organisation #{organisation.name} ?

        Toutes ses indisponibilités et ses plages d'ouvertures seront supprimées de manière irréversible.

        Cet agent appartenant à d'autres organisations, son compte ne sera pas supprimé. L'agent pourra toujours se connecter aux autres organisations, et vous ne pourrez pas recréer son compte pour l'affecter à un service différent.
      STR
    end
  end

  private

  def agent_removal_service
    @agent_removal_service ||= AgentRemoval.new(agent, organisation)
  end
end
