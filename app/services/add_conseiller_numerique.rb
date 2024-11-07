class AddConseillerNumerique
  class ConseillerNumerique
    include ActiveModel::Model

    attr_accessor :email, :first_name, :last_name, :secondary_email, :old_email
    attr_writer :external_id

    def external_id
      "conseiller-numerique-#{@external_id}"
    end
  end

  class Structure
    include ActiveModel::Model

    attr_accessor :name, :address, :external_id
  end

  def initialize(agent:, organisation:, lieux:)
    @conseiller_numerique = ConseillerNumerique.new(agent)
    @structure = Structure.new(organisation)
    @lieux = lieux.map do |lieu_hash|
      OpenStruct.new(lieu_hash)
    end
  end

  def self.process!(agent:, organisation:, lieux:)
    new(agent:, organisation:, lieux:).process!
  end

  def process!
    ActiveRecord::Base.transaction do
      organisation = find_or_create_organisation

      find_or_invite_agent(organisation)
    end
  end

  def find_or_create_organisation
    Organisation.find_by(territory: territory, external_id: @structure.external_id) || create_organisation
  end

  private

  def find_or_invite_agent(organisation)
    existing_agent = Agent.where(deleted_at: nil).find_by(external_id: @conseiller_numerique.external_id)
    if existing_agent
      unless organisation.in?(existing_agent.organisations)
        existing_agent.roles.create!(organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
      end

      agent_with_old_email&.update(email: @conseiller_numerique.email)
    else
      invite_agent(organisation)
    end
  end

  def invite_agent(organisation)
    Agent.invite!(
      {
        email: @conseiller_numerique.email,
        first_name: @conseiller_numerique.first_name.capitalize,
        last_name: @conseiller_numerique.last_name,
        external_id: @conseiller_numerique.external_id,
        services: [service],
        password: SecureRandom.base64(32),
        roles_attributes: [{ organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN }],
      }
    ).tap do |agent|
      agent.agent_territorial_access_rights.find_or_create_by!(territory: territory)
    end
  end

  def create_organisation
    organisation = Organisation.create!(
      external_id: @structure.external_id,
      name: next_available_organisation_name,
      territory: territory,
      verticale: :rdv_aide_numerique
    )
    create_motifs(organisation)
    create_lieux(organisation)
    organisation
  end

  def next_available_organisation_name
    return @structure.name if available?(@structure.name)

    name_with_city = "#{@structure.name} - #{city_name}"
    return name_with_city if available?(name_with_city)

    number_of_similar_structures = territory.organisations.where("name like ?", "%#{name_with_city}%").count

    "#{name_with_city} (#{number_of_similar_structures + 1})"
  end

  def available?(name)
    territory.organisations.where(name: name).none?
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

  def create_lieux(organisation)
    @lieux.each do |lieu|
      longitude, latitude = coordinates(lieu.address)

      Lieu.create!(
        name: lieu.name,
        organisation: organisation,
        latitude: latitude,
        longitude: longitude,
        address: lieu.address,
        availability: :enabled
      )
    end
  end

  def coordinates(address)
    adresse_api_response(address).dig("features", 0, "geometry", "coordinates")
  end

  def city_name
    adresse_api_response(@lieux.first.address).dig("features", 0, "properties", "city")
  end

  def adresse_api_response(address)
    zipcode_regex = /\d{5}/
    zipcode = address[zipcode_regex]

    response = Faraday.get(
      "https://api-adresse.data.gouv.fr/search/",
      q: address,
      postcode: zipcode
    )
    JSON.parse(response.body)
  end

  def territory
    @territory ||= Territory.find_by(name: "Conseillers Numériques")
  end

  def service
    @service ||= Service.find_by(name: Service::CONSEILLER_NUMERIQUE)
  end
end
