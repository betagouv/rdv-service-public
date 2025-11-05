module SuperAdmins
  class ComptesController < SuperAdmins::ApplicationController
    def new
      @territory_creation_request = policy_scope(TerritoryCreationRequest, policy_scope_class: SuperAdmin::TerritoryCreationRequestPolicy::Scope).find_by(id: params[:request_id])
      @agent = policy_scope(Agent, policy_scope_class: SuperAdmin::AgentPolicy::Scope).find_by(id: params[:agent_id]) || @territory_creation_request&.agent

      super
    end

    def create
      compte_params[:agent][:invited_by] = current_super_admin

      territory_creation_request_scope = policy_scope(TerritoryCreationRequest, policy_scope_class: SuperAdmin::TerritoryCreationRequestPolicy::Scope)
      territory_creation_request = territory_creation_request_scope.find_by(id: params.dig(:compte, :territory_creation_request_id))

      compte = Compte.new(compte_params, current_domain:, territory_creation_request:)
      authorize_resource(compte)

      if compte.save!
        if params[:add_to_crm]
          CreateCrmPageJob.perform_later(compte.territory.id)
        end

        redirect_to(
          super_admins_agent_path(compte.agent),
          notice: "Le nouvel espace a été créé, et une invitation a été envoyée à #{compte.agent.email}"
        )
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, compte),
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
