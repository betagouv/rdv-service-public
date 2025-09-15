class Agent::ExternalReferencePolicy < ApplicationPolicy
  alias current_agent pundit_user

  class Scope < Scope
    alias current_agent pundit_user

    def resolve
      scope.where(territory_id: @pundit_user.organisations.pluck(:territory_id) + [nil])
        .joins(:oauth_application).merge(
          OauthApplication.joins(:access_tokens).merge(current_agent.access_tokens)
        ).uniq
    end
  end
end
