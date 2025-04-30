module SuperAdmins
  class TerritoryCreationRequestsController < SuperAdmins::ApplicationController
    def index
      @territory_creation_requests = policy_scope(TerritoryCreationRequest.where(response: params[:response]), policy_scope_class: SuperAdmin::TerritoryCreationRequestPolicy::Scope)

      # le module Administrate::Punditize oblige à faire un appel à #authorize même si on est sur l'index
      authorize(@territory_creation_requests, policy_class: SuperAdmin::TerritoryCreationRequestPolicy)
    end

    def edit
      @territory_creation_request = TerritoryCreationRequest.find(params[:id])
      authorize(@territory_creation_request, policy_class: SuperAdmin::TerritoryCreationRequestPolicy)
    end

    def update
      @territory_creation_request = TerritoryCreationRequest.find(params[:id])
      authorize_resource(@territory_creation_request)

      if @territory_creation_request.update(params.require(:territory_creation_request).permit(:response))
        redirect_to super_admins_territory_creation_requests_path, flash: { success: "Demande traitée" }
      else
        flash.now[:error] = @territory_creation_request.errors.full_messages.join(" ")
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
