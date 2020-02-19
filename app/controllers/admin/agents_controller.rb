module Admin
  class AgentsController < Admin::ApplicationController
    def sign_in_as
      agent = Agent.find(params[:id])
      if sign_in_as_allowed?
        sign_out(:user)
        sign_in(:agent, agent, bypass: true)
        redirect_to root_url
      else
        flash[:error] = "Fonctionnalité désactivée sur cet environnement."
        redirect_to admin_agent_path(agent)
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
        redirect_to(
          [namespace, resource],
          notice: translate_with_resource("create.success")
        )
      end
    end

    def invite
      requested_resource.invite!
      redirect_to(
        [namespace, requested_resource],
        notice: 'Invitation envoyée'
      )
    end
  end
end
