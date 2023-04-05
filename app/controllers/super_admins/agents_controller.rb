# frozen_string_literal: true

module SuperAdmins
  class AgentsController < SuperAdmins::ApplicationController
    def sign_in_as
      agent = Agent.find(params[:id])
      if sign_in_as_allowed?
        sign_out(:user)
        bypass_sign_in(agent, scope: :agent)
        redirect_to root_url
      else
        flash[:error] = "Fonctionnalité désactivée sur cet environnement."
        redirect_to super_admins_agent_path(agent)
      end
    end

    def create
      resource = resource_class.new(resource_params)
      authorize_resource(resource)

      agent = resource_class.invite!(resource_params) do |u|
        u.skip_invitation = true
      end

      if agent.errors.any?
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, resource),
        }
      else
        agent.organisations.pluck(:territory_id).uniq.each do |territory_id|
          AgentTerritorialAccessRight.find_or_create_by!(agent: agent, territory_id: territory_id)
        end
        redirect_to(
          [namespace, resource],
          notice: translate_with_resource("create.success")
        )
      end
    end

    def update
      super
      agent = Agent.find(params[:id])
      agent.organisations.pluck(:territory_id).uniq.each do |territory_id|
        AgentTerritorialAccessRight.find_or_create_by!(agent: agent, territory_id: territory_id)
      end
    end

    def invite
      requested_resource.invited_by = current_super_admin
      requested_resource.invite!(nil, validate: false)
      redirect_to(
        [namespace, requested_resource],
        notice: "Invitation envoyée"
      )
    end
  end
end
