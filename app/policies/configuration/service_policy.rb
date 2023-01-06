# frozen_string_literal: true

class Configuration::ServicePolicy
  def initialize(context, service)
    @current_agent = context.agent
    @current_territory = context.territory
    @service = service
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@current_territory)
  end

  def allow_to_manage_services?
    @current_agent.access_rights_for_territory(@current_territory)&.allow_to_manage_teams? || false
  end

  alias new? territorial_admin?
  alias version? allow_to_manage_services?

  class Scope
    def initialize(context, _scope)
      @current_territory = context.territory
    end

    def resolve
      Service.all
    end
  end
end
