module SuperAdmins
  class TerritoryCreationRequestsController < SuperAdmins::ApplicationController
    def edit
      super
    end

    def update
      ProcessTerritoryCreationRequestForm.new
    end
  end

  private

  def permitted_params
    params.require(:process_territory_creation_request_form).permit(service_ids: [])
  end
end
