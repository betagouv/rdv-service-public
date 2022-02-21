# frozen_string_literal: true

class Configuration::TerritoryPolicy

  def initialize(context, territory)
    @context = context
    @territory = territory
  end

  def show?
    @context.agent.territorial_admin_in?(@territory)
  end

end

