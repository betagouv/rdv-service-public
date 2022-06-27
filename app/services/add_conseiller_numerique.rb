# frozen_string_literal: true

class AddConseillerNumerique
  class ConseillerNumerique
    include ActiveModel::Model

    attr_accessor :email, :first_name, :last_name, :external_id
  end

  class Structure
    include ActiveModel::Model

    attr_accessor :name, :address, :external_id
  end

  def initialize(conseiller_numerique_attributes)
    structure_attributes = conseiller_numerique_attributes.delete(:structure)
    @conseiller_numerique = ConseillerNumerique.new(conseiller_numerique_attributes)
    @structure = Structure.new(structure_attributes)
  end

  def self.process!(conseiller_numerique_attributes)
    new(conseiller_numerique_attributes).process!
  end

  def process!
    ActiveRecord::Base.transaction do
      organisation = find_or_create_organisation

      find_or_invite_agent(organisation)
    end
  end

  private

  def find_or_invite_agent(organisation)
    agent = Agent.where(deleted_at: nil).find_by(external_id: @conseiller_numerique.external_id)

    agent || Agent.invite!(
      email: @conseiller_numerique.email,
      first_name: @conseiller_numerique.first_name.capitalize,
      last_name: @conseiller_numerique.last_name,
      external_id: @conseiller_numerique.external_id,
      service: service,
      password: SecureRandom.hex,
      roles_attributes: [{ organisation: organisation, level: AgentRole::LEVEL_ADMIN }]
    )
  end

  def find_or_create_organisation
    Organisation.find_by(external_id: @structure.external_id) || create_organisation
  end

  def create_organisation
    organisation = Organisation.create!(
      external_id: @structure.external_id,
      name: @structure.name,
      territory: territory
    )
    create_motifs(organisation)
    create_lieu(organisation)
    organisation
  end

  def create_motifs(organisation)
    Motif.create!(
      name: "Accompagnement individuel",
      color: "#99CC99",
      default_duration_in_min: 60,
      location_type: :public_office,
      organisation: organisation,
      service: service
    )

    Motif.create!(
      name: "Atelier collectif",
      color: "#4A86E8",
      default_duration_in_min: 120,
      location_type: :public_office,
      collectif: true,
      organisation: organisation,
      service: service
    )
  end

  def create_lieu(organisation)
    zipcode_regex = /\d{5}/
    zipcode = @structure.address[zipcode_regex]
    longitude, latitude = geocode(@structure.address, zipcode)

    Lieu.create!(
      name: @structure.name,
      organisation: organisation,
      latitude: latitude,
      longitude: longitude,
      address: @structure.address,
      availability: :enabled
    )
  end

  def geocode(street_address, zipcode)
    response = Faraday.get(
      "https://api-adresse.data.gouv.fr/search/",
      q: street_address,
      postcode: zipcode
    )
    response_hash = JSON.parse(response.body)
    response_hash.dig("features", 0, "geometry", "coordinates")
  end

  def territory
    @territory ||= Territory.find_by(name: "Conseillers Numériques")
  end

  def service
    @service ||= Service.find_by(name: "Conseiller Numérique")
  end
end
