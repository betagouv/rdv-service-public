# frozen_string_literal: true

module SuperAdmins
  class MairieComptesController < SuperAdmins::ApplicationController
    include GeoCoding

    def create
      resource = resource_class.new(resource_params)
      authorize_resource(resource)

      lieu = nil
      Lieu.transaction do
        service = Service.find_by(name: Service::MAIRIE)
        organisation = create_organisation
        invite_agent(organisation, service)
        create_motif(organisation, service)
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
        territory: Territory.find_by(name: "Mairies"),
        verticale: :rdv_mairie
      )
    end

    def invite_agent(organisation, service)
      Agent.invite!(
        email: resource_params[:agent_email],
        first_name: resource_params[:agent_first_name],
        last_name: resource_params[:agent_last_name],
        service: service,
        password: SecureRandom.hex,
        roles_attributes: [{ organisation: organisation, level: AgentRole::LEVEL_ADMIN }],
        invited_by: current_super_admin
      )
    end

    def create_motif(organisation, service)
      Motif.create!(
        name: "Passeport / Carte d'identité",
        color: "#99CC99",
        default_duration_in_min: 30,
        location_type: :public_office,
        organisation: organisation,
        service: service,
        bookable_by: :everyone
      )
    end

    def create_lieu(organisation)
      longitude, latitude = find_geo_coordinates(resource_params[:address])

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
