territory = Territory.create!(
  name: "Visioplainte"
)

service_police = Service.create!(name: "Police nationale")
service_gendarmerie = Service.create!(name: "Gendarmerie nationale")

territory.services << service_pn
territory.services << service_gn

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
  service: service_police,
  organisation: orga_police
)
Motif.create!(
  name: "Dépôt de plainte par visioconférence",
  default_duration_in_min: 30,
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
AgentTerritorialAccessRight.create(agent: superviseur_police, territory: territory)

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
