class Agents::DuplicateUsersSuggestionsController < AgentAuthController
  before_action :set_organisation

  def index
    @duplicate_users_suggestions = policy_scope(User).where.not(potential_duplicate: nil)
  end
end
