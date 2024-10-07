module ExplicitPunditConcern
  extend ActiveSupport::Concern

  private

  # NOTE: it is a project-specific choice to always pass `policy_class` explicitly
  def authorize(record, query = nil, policy_class:)
    super(record, query, policy_class: policy_class) # rubocop:disable Style/SuperArguments
  end

  # NOTE: it is a project-specific choice to always pass `policy_scope_class` explicitly
  def policy_scope(scope, policy_scope_class:)
    super(scope, policy_scope_class: policy_scope_class) # rubocop:disable Style/SuperArguments
  end

  # NOTE: it is a project-specific choice to always pass `policy_class` explicitly
  def policy(record, policy_class:)
    policy_class.new(pundit_user, record)
  end
end
