module SuperAdmins
  class ComptesController < SuperAdmins::ApplicationController
    def new
      @territory_creation_request = policy_scope(TerritoryCreationRequest, policy_scope_class: SuperAdmin::TerritoryCreationRequestPolicy::Scope).find_by(id: params[:request_id])
      @agent = policy_scope(Agent, policy_scope_class: SuperAdmin::AgentPolicy::Scope).find_by(id: params[:agent_id]) || @territory_creation_request&.agent

      super
    end

    def create
      compte_params[:agent][:invited_by] = current_super_admin
      compte = Compte.new(compte_params, current_domain)
      authorize_resource(compte)

      if compte.save!
        # TODO: enregistrer la réponse sur le creation request aussi
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
        territory: %i[name departement_number category],
        organisation: %i[name ants_connectable],
        lieu: %i[address latitude longitude],
        agent: %i[id first_name last_name email service_ids]
      )
    end
  end
end
