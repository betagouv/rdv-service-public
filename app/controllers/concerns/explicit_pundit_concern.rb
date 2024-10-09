# Ce concern permet de s'assurer que l'on respecte les bonnes pratiques
# définies pour ce projet en terme d'usage de pundit.
# En particulier, les appels aux méthodes authorize(), policy_scope() et policy()
# doivent être faits en passant la classe de la policy explicitement.
# Le passage explicite de la classe a pour avantage de :
#   - permettre de trouver facilement tous les usages d'une policy
#   - démystifier pundit : une policy est une simple classe ruby
module ExplicitPunditConcern
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization
  end

  private

  def authorize(record, query = nil, policy_class:)
    super(record, query, policy_class: policy_class) # rubocop:disable Style/SuperArguments
  end

  def policy_scope(scope, policy_scope_class:)
    super(scope, policy_scope_class: policy_scope_class) # rubocop:disable Style/SuperArguments
  end

  def policy(record, policy_class:)
    policy_class.new(pundit_user, record)
  end
end
