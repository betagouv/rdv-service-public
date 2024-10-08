territory = Territory.create(name: "placeholder")

territory.update_columns(name: Territory::VISIOPLAINTE_NAME) # rubocop:disable Rails/SkipsModelValidations

service_gendarmerie = Service.create!(name: "Gendarmerie Nationale", short_name: "Gendarmerie")

territory.services << service_gendarmerie

orga_gendarmerie = Organisation.create!(
  name: "Plateforme Visioplainte Gendarmerie",
  territory: territory
)

motif = Motif.create!(
  name: "Dépôt de plainte par visioconférence",
  default_duration_in_min: 30,
  min_public_booking_delay: 2 * 60 * 60,
  color: "#FF7C00",
  location_type: :visio,
  service: service_gendarmerie,
  visibility_type: Motif::VISIBLE_AND_NOT_NOTIFIED,
  organisation: orga_gendarmerie
)

superviseur_gendarmerie = Agent.new(
  first_name: "Gaston",
  last_name: "Bidon",
  email: "gaston.bidon@visioplainte.sandbox.gouv.fr",
  uid: "gaston.bidon@visioplainte.sandbox.gouv.fr",
  password: "Rdvservicepublictest1!",
  services: [service_gendarmerie],
  roles_attributes: [
    { organisation: orga_gendarmerie, access_level: AgentRole::ACCESS_LEVEL_ADMIN },
  ]
)
superviseur_gendarmerie.skip_confirmation!
superviseur_gendarmerie.save!
AgentTerritorialAccessRight.create(agent: superviseur_gendarmerie, territory: territory)

guichet_gendarmerie = Agent.create!(
  last_name: "Guichet 1",
  services: [service_gendarmerie],
  roles_attributes: [
    { organisation: orga_gendarmerie, access_level: AgentRole::ACCESS_LEVEL_INTERVENANT },
  ]
)

Agent.create!(
  last_name: "Guichet 2",
  services: [service_gendarmerie],
  roles_attributes: [
    { organisation: orga_gendarmerie, access_level: AgentRole::ACCESS_LEVEL_INTERVENANT },
  ]
)
