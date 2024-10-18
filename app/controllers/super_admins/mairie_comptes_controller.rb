module SuperAdmins
  class MairieComptesController < SuperAdmins::ApplicationController
    def create
      resource = resource_class.new(resource_params)
      authorize_resource(resource)

      lieu = nil
      Lieu.transaction do
        service = Service.find_by(name: Service::MAIRIE)
        organisation = create_organisation
        invite_agent(organisation, service)
        create_motifs(organisation, service)
        lieu = create_lieu(organisation)
      end

      if lieu.errors.any?
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, lieu),
        }
      else
        redirect_to(
          [namespace, resource],
          notice: translate_with_resource("create.success")
        )
      end
    end

    private

    def create_organisation
      Organisation.create!(
        name: resource_params[:name],
        territory: Territory.mairies,
        verticale: :rdv_mairie
      )
    end

    def invite_agent(organisation, service)
      Agent.invite!(
        email: resource_params[:agent_email],
        first_name: resource_params[:agent_first_name],
        last_name: resource_params[:agent_last_name],
        services: [service],
        password: SecureRandom.base64(32),
        roles_attributes: [{ organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN }],
        invited_by: current_super_admin
      )
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

    def create_lieu(organisation)
      longitude, latitude = GeoCoding.new.find_geo_coordinates(resource_params[:address])

      Lieu.create(
        name: resource_params[:name],
        address: resource_params[:address],
        longitude: longitude,
        latitude: latitude,
        availability: :enabled,
        organisation: organisation
      )
    end
  end
end
