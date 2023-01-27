# frozen_string_literal: true

class AgentAuthController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  layout "application_agent"

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  helper_method :current_organisation, :current_territory, :policy_scope, :from_modal?

  private

  def pundit_user
    @pundit_user ||= AgentOrganisationContext.new(current_agent, current_organisation)
  end
  helper_method :pundit_user

  def authorize(record, *args)
    record.class.module_parent == Agent ? super(record, *args) : super([:agent, record], *args)
  end

  def policy_scope(clasz)
    clasz.module_parent == Agent ? super(record) : super([:agent, clasz])
  end

  def set_organisation
    @organisation = current_organisation
  end

  def current_organisation
    @current_organisation ||= current_agent.organisations.find(params[:organisation_id])
  end

  def current_territory
    @current_territory ||= current_organisation.territory
  end

  def from_modal?
    params[:modal].present?
  end
end
