module SuperAdmins
  class TerritoryCreationRequestsController < SuperAdmins::ApplicationController
    def index
      @territory_creation_requests = policy_scope(TerritoryCreationRequest.where(response: params[:status]), policy_scope_class: SuperAdmin::TerritoryCreationRequestPolicy::Scope)
      authorize(@territory_creation_requests, policy_class: SuperAdmin::TerritoryCreationRequestPolicy)
    end

    def edit
      super
    end

    def update
      ProcessTerritoryCreationRequestForm.new
      compte_params[:agent][:invited_by] = current_super_admin
      compte = Compte.new(compte_params, current_domain)
      authorize_resource(compte)

      if compte.save!
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
  end

  private

  def permitted_params
    params.require(:process_territory_creation_request_form).permit(service_ids: [])
  end

  def compte_params
    params.require(:compte).permit(
      territory: %i[name category],
      organisation: %i[name],
      agent: %i[service_ids]
    )
  end
end
