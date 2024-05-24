class Configuration::MotifPolicy < Agent::MotifPolicy
  private

  def current_agent
    pundit_user.agent
  end

  class Scope
    def initialize(context, _scope)
      @current_territory = context.territory
    end

    def resolve
      Motif.where(organisation: @current_territory.organisations)
    end
  end
end
