module SuperAdmins
  class TerritoryCreationRequestsController < SuperAdmins::ApplicationController
    def index
      @territory_creation_requests = policy_scope(TerritoryCreationRequest.where(response: params[:status]), policy_scope_class: SuperAdmin::TerritoryCreationRequestPolicy::Scope)
      authorize(@territory_creation_requests, policy_class: SuperAdmin::TerritoryCreationRequestPolicy)
    end

    def update
      @territory_creation_request = TerritoryCreationRequest.find(params[:id])
      authorize_resource(@territory_creation_request)

      if @territory_creation_request.update(params.require(:territory_creation_request).permit(:response))
        redirect_to super_admins_territory_creation_requests_path, flash: "Demande traitée"
      else
        # TODO: gérer le cas d'une demande déjà traitée
        # TODO: ajouter le cas d'une demande en attente ?
        render :edit, status: :unprocessable_entity
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
