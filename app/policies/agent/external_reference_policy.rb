class Agent::ExternalReferencePolicy < ApplicationPolicy
  alias current_agent pundit_user

  def show?
    record.territory_id.in?(@pundit_user.agent_territorial_access_rights.select(:territory_id)) &&
      record.oauth_application.in?(OauthApplication.joins(:access_tokens).merge(@pundit_user.access_tokens))
  end

  class Scope < Scope
    alias current_agent pundit_user

    def resolve
      scope.where(territory_id: @pundit_user.agent_territorial_access_rights.select(:territory_id))
        .joins(:oauth_application).merge(
          OauthApplication.joins(:access_tokens).merge(current_agent.access_tokens)
        )
    end
  end
end
