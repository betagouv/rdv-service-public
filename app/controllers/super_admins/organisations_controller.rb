module SuperAdmins
  class OrganisationsController < SuperAdmins::ApplicationController
    def update
      super

      if requested_resource.saved_change_to_ants_connectable?(to: true)
        requested_resource.territory.add_ants_motif_categories
      end
    end
  end
end
