module CurrentAgentInPolicyConcern
  extend ActiveSupport::Concern

  included do
    alias_method :context, :pundit_user

    def current_agent
      # on veut peu à peu supprimer les usages des contextes mais c’est compliqué de tout faire d’un coup
      # cette méthode permet de simplifier la transition : on accepte des context.agent ou des agents directement
      if context.is_a? Agent
        context
      else
        context.agent
      end
    end
  end
end
