class Configuration::MotifPolicy
  class Scope
    def initialize(context, _scope)
      @current_territory = context.territory
    end

    def resolve
      Motif.where(organisation: @current_territory.organisations)
    end
  end
end
