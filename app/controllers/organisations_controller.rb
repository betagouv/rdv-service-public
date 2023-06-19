# frozen_string_literal: true

class OrganisationsController < ApplicationController
  layout "application"

  def new
    @organisation = Organisation.new(territory: Territory.new)
    @organisation.agent_roles.build(access_level: AgentRole::ACCESS_LEVEL_ADMIN)
    @organisation.agent_roles.first.build_agent
  end

  def create
    @organisation = Organisation.new(organisation_params)
    @organisation.agent_roles.each do |agent_role|
      # because we're not passing through the regular `.invite!` method, we
      # have to hack our way into creating a user that bypasses validations and
      # callbacks:
      agent_role.agent.skip_confirmation!
      agent_role.agent.skip_invitation = true
      agent_role.agent.define_singleton_method(:password_required?) { false }
      agent_role.agent.define_singleton_method(:postpone_email_change?) { false }
      # forces devise_token_auth sync_uid to run
      @organisation.territory.roles.build(agent: agent_role.agent)
    end

    render :new unless @organisation.save
  end

  def organisation_params
    params.require(:organisation)
      .permit(
        :name,
        agent_roles_attributes: [:access_level, { agent_attributes: %i[email service_id] }],
        territory_attributes: [:departement_number]
      )
  end
end
