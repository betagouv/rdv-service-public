service = Service.create!(name: "Action Sociale", short_name: "AS CCAS")

Compte.new(
  {
    territory: {
      name: "Montélimar",
      departement_number: "26",
    },
    organisation: {
      name: "CCAS de Montélimar",
    },
    lieu: {
      address: "10 Rue Cuiraterie, 26200 Montélimar",
      latitude: "44.5569244",
      longitude: "4.7521632",
    },
    agent: {
      first_name: "Cécile",
      last_name: "Astier",
      email: "cecile.astier@demo-rdv-service-public.fr",
      service_ids: [service.id],
    },
  }, Domain::RDV_MAIRIE
).save!

agent = Agent.find_by(email: "cecile.astier@demo-rdv-service-public.fr")

agent.update!(
  invitation_token: nil,
  invitation_accepted_at: 10.days.ago,
  invitation_created_at: nil,
  invitation_sent_at: nil,
  confirmed_at: 10.days.ago,
  password: "Rdvservicepublictest1!"
)

orga_ccas = agent.organisations.first

user = User.new(
  first_name: "Patricia",
  last_name: "Duroy",
  email: "patricia@demo.rdv-solidarites.fr",
  birth_date: Date.parse("20/06/1975"),
  password: "Rdvservicepublictest1!",
  phone_number: "0101010101",
  organisation_ids: [orga_ccas.id],
  created_through: "user_sign_up"
)

user.skip_confirmation!
user.save!

# Un agent pour tester l'absence d'orga et de services
agent = Agent.new(
  email: "bob-sans-orga@demo.rdv-solidarites.fr",
  uid: "bob-sans-orga@demo.rdv-solidarites.fr",
  first_name: "Bob",
  last_name: "Sans Organisation",
  password: "Rdvservicepublictest1!",
  services: [],
  invitation_accepted_at: 1.day.ago,
  roles_attributes: [],
  agent_territorial_access_rights_attributes: []
)
agent.skip_confirmation!
agent.save!
