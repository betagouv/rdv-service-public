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

  
  alias new? territorial_admin?
  alias versions? territorial_admin?
  alias edit? territorial_admin?
  alias create? territorial_admin?
  alias destroy? territorial_admin?
  alias update? territorial_admin?
  alias display? territorial_admin?

  class Scope
    def initialize(context, _scope)
      @current_territory = context.territory
    end

    def resolve
      Service.all
    end
  end
end
