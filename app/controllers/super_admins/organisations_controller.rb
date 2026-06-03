module SuperAdmins
  class OrganisationsController < SuperAdmins::ApplicationController
    def create_france_connect_motifs
      ActiveRecord::Base.transaction do
        MotifTemplates::FranceService.upsert_services!
        MotifTemplates::FranceService.upsert_motifs!(requested_resource)
      end
      mass_edit_url = admin_territory_motifs_url(territory_id: requested_resource.territory_id)
      flash[:success] = "Les motifs France Service on bien été créés. Ils sont éditables en masse ici : #{mass_edit_url}"
      redirect_to super_admins_organisation_path(id: requested_resource.id)
    end

    def update
      super

      if requested_resource.saved_change_to_ants_connectable?(to: true)
        requested_resource.territory.add_ants_motif_categories
      end
    end
  end
end
