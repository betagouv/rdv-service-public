module SuperAdmins
  class ComptesController < SuperAdmins::ApplicationController
    def create
      compte_params[:agent][:invited_by] = current_super_admin
      compte = Compte.new(compte_params, current_domain)
      authorize_resource(compte)

      ActiveRecord::Base.transaction do
        compte.save
      end

      if 
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
        organisation: %i[name ants_connectable],
        lieu: %i[address latitude longitude],
        agent: %i[first_name last_name email service_ids]
      )
    end

    def create_mairie_ressources
      service = Service.find_by(name: Service::MAIRIE)
      create_motifs(organisation, service)

    end

    def create_motifs(organisation, service)
      create_motif(organisation, service, "Carte d'identité", Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME)
      create_motif(organisation, service, "Passeport", Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME)
      create_motif(organisation, service, "Passeport et carte d'identité", Api::Ants::EditorController::CNI_AND_PASSPORT_MOTIF_CATEGORY_NAME)
    end

    def create_motif(organisation, service, name, motif_category_name)
      Motif.create!(
        name: name,
        color: "#99CC99",
        default_duration_in_min: 15,
        location_type: :public_office,
        organisation: organisation,
        service: service,
        motif_category: MotifCategory.find_by(name: motif_category_name),
        bookable_by: :everyone
      )
    end
  end
end
