territory = Territory.create(name: "placeholder")

territory.update_columns(name: Territory::VISIOPLAINTE_NAME) # rubocop:disable Rails/SkipsModelValidations

service_police = Service.create!(name: "Police Nationale", short_name: "Police")
service_gendarmerie = Service.create!(name: "Gendarmerie Nationale", short_name: "Gendarmerie")

territory.services << service_police
territory.services << service_gendarmerie

orga_police = Organisation.create!(
  name: "Plateforme Visioplainte Police",
  territory: territory
)
orga_gendarmerie = Organisation.create!(
  name: "Plateforme Visioplainte Gendarmerie",
  territory: territory
)

motif_police = Motif.create!(
  name: "Dépôt de plainte par visioconférence",
  default_duration_in_min: 30,
  color: "#FF7C00",
  location_type: :visio,
  service: service_police,
  organisation: orga_police
)
Motif.create!(
  name: "Dépôt de plainte par visioconférence",
  default_duration_in_min: 30,
  color: "#FF7C00",
  location_type: :visio,
  service: service_gendarmerie,
  organisation: orga_gendarmerie
)

superviseur_police = Agent.create!(
  first_name: "Francis",
  last_name: "Factice",
  email: "francis.factice@visioplainte.sandbox.gouv.fr",
  uid: "francis.factice@visioplainte.sandbox.gouv.fr",
  password: "Rdvservicepublictest1!",
  services: [service_police],
  roles_attributes: [
    { organisation: orga_police, access_level: AgentRole::ACCESS_LEVEL_ADMIN },
  ]
)
AgentTerritorialAccessRight.create(agent: superviseur_police, territory: territory)

superviseur_gendarmerie = Agent.create(
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
AgentTerritorialAccessRight.create(agent: superviseur_gendarmerie, territory: territory)

guichet_police1 = Agent.create!(
  last_name: "Guichet 1",
  services: [service_police],
  roles_attributes: [
    { organisation: orga_police, access_level: AgentRole::ACCESS_LEVEL_INTERVENANT },
  ]
)

PlageOuverture.create!(
  title: "Permanence classique",
  organisation: orga_police,
  agent: guichet_police1,
  motifs: [motif_police],
  first_day: Date.tomorrow,
  start_time: Tod::TimeOfDay.new(8),
  end_time: Tod::TimeOfDay.new(12),
  recurrence: Montrose.every(:week, day: [1, 2, 3, 4, 5], interval: 1, starts: Date.tomorrow, on: %i[monday tuesday thursday friday])
)
