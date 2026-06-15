module SuperAdmins
  class OrganisationsController < SuperAdmins::ApplicationController
    def create_france_connect_motifs
      motif_creator = MotifTemplates::FranceService.new(requested_resource)
      if motif_creator.upsert
        mass_edit_path = admin_territory_motifs_path(territory_id: requested_resource.territory_id)
        flash[:success] = view_context.sanitize("Les motifs France Service on bien été créés. Ils sont éditables en masse #{view_context.link_to('ici', mass_edit_path)}")
      else
        flash[:error] = "Certains motifs n'ont pas pu être créés"
      end
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
