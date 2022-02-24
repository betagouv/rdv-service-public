# frozen_string_literal: true

class Configuration::TeamPolicy

  def initialize(context, team)
    @context = context
    @team = team
  end

  def territorial_admin?
    @context.agent.territorial_admin_in?(@context.territory)
  end

  alias new? territorial_admin?
  alias create? territorial_admin?

  class Scope
    def initialize(context, _scope)
      puts "init scop team ?"
      @context  = context
    end

    def resolve
      puts "resolve scop team ?"
      puts @context.territory.inspect
      @context.territory.teams
    end
  end
end
