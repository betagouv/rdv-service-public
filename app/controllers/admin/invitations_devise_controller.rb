# frozen_string_literal: true

class Admin::InvitationsDeviseController < Devise::InvitationsController
  protected

  def services
    Agent::ServicePolicy::AdminScope.new(pundit_user, Service).resolve
  end

  def pundit_user
    AgentOrganisationContext.new(current_agent, current_organisation)
  end

  def current_organisation
    Organisation.find(params[:organisation_id])
  end
  helper_method :current_organisation

  def policy_scope(*args, **kwargs)
    super([:agent, *args], **kwargs)
  end
  helper_method :policy_scope

  def authorize(*args, **kwargs)
    super([:agent, *args], **kwargs)
  end
end
