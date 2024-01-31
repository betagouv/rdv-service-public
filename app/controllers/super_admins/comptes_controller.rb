module SuperAdmins
  class ComptesController < SuperAdmins::ApplicationController
    def create
      compte_params[:agent][:invited_by] = current_super_admin
      resource = Compte.new(compte_params)
      authorize_resource(resource)

      if resource.save
        yield(resource) if block_given?
        redirect_to(
          after_resource_created_path(resource),
          notice: "Le nouveau compte a été créé, et une invitation a été envoyée à #{compte_params.dig(:agent, :email)}"
        )
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, resource),
        }, status: :unprocessable_entity
      end
    end

    private

    def compte_params
      params.require(:compte).permit(
        territory: %i[name departement_number],
        organisation: :name,
        lieu: %i[address latitude longitude],
        agent: %i[first_name last_name email service_ids]
      )
    end
  end
end
