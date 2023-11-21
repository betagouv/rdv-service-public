class Configuration::Admin::SectorisationTestFormPolicy
  class Scope
    def initialize(_context, scope)
      @scope = scope
    end

    def resolve
      @scope
    end
  end
end
