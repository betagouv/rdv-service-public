# frozen_string_literal: true

class Configuration::SectorAttributionPolicy
  def initialize(context, agent)
    @current_agent = context.agent
    @current_territory = context.territory
    @agent = agent
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@current_territory)
  end

  alias new? territorial_admin?
  alias create? territorial_admin?
  alias destroy? territorial_admin?
end
