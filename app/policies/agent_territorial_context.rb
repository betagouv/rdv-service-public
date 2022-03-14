# frozen_string_literal: true

# TODO: supprimer ce context, nous devrions pouvoir utiliser le territoire de l'objet sur lequel on vérifier l'accès
class AgentTerritorialContext
  attr_reader :agent, :territory

  def initialize(agent, territory)
    @agent = agent
    @territory = territory
  end
end
