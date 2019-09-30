module Admin
  class ProsController < Admin::ApplicationController
    def sign_in_as
      sign_out(:user)
      pro = Pro.find(params[:id])
      sign_in(:pro, pro, bypass: true)
      redirect_to root_url
    end

    def create
      resource = resource_class.new(resource_params)
      authorize_resource(resource)

      resource_class.invite!(resource_params) do |u|
        u.skip_invitation = true
      end

      redirect_to(
        [namespace, resource],
        notice: translate_with_resource("create.success"),
      )
    end

    def invite
      requested_resource.deliver_invitation
      redirect_to(
        [namespace, requested_resource],
        notice: 'Invitation envoyée',
      )
    end
  end
end
