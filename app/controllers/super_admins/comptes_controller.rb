module SuperAdmins
  class ComptesController < SuperAdmins::ApplicationController
    def create
      compte_params[:agent][:invited_by] = current_super_admin
      compte = Compte.new(compte_params)
      authorize_resource(compte)

      if compte.save
        redirect_to(
          super_admins_agent_path(compte.agent),
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
