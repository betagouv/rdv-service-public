RSpec.describe "Prise de rendez-vous entre agents", js: true do
  let(:service) { create(:service, name: "Dinum", short_name: "Dinum") }

  before do
    Compte.new(
      {
        territory: { name: "Betagouv" },
        organisation: { name: "Equipe produit de Mon Permis de Construire" },
        agent: {
          first_name: "Francis",
          last_name: "Factice",
          email: "francis.factice@demo-rdv-service-public.gouv.fr",
          service_ids: [service.id],
        },
      }, current_domain: Domain::RDV_MAIRIE
    ).save!

    Motif.where.not(location_type: :visio).update_all(deleted_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
  end

  specify do
    agent = Agent.find_by(first_name: "Francis")
    agent.update!(confirmed_at: 10.days.ago)

    login_as(agent, scope: :agent)

    doc = SpecToDoc.start_scenario("Prise de rendez-vous entre agents", self)

    doc.start_section("Côté agent")
    doc.add_text(<<~TEXT
      <h3>Contexte</h3>
      <p>
        Je suis un agent du service public, par exemple quelqu'un qui travaille pour une startup d'état de la Dinum.
      </p>
      <p>
        Je souhaite proposer de la prise de rendez-vous à d'autres agents du service public, en leur envoyant un lien avec lequel ils pourront directement prendre rendez-vous.
      </p>
      <p>
        J'ai un compte sur RDV Service Public, sur lequel j'ai juste un motif "Suivi de dossier" par visio.
      </p>
    TEXT
      .html_safe) # rubocop:disable Rails/OutputSafety

    visit "http://www.rdv-mairie-test.localhost/agents/agenda"

    doc.add_screenshot(page,
                       text: "J'ouvre mon espace RDV Service Public",
                       wait_for: "Agenda")

    click_on "Plages d'ouverture"
    doc.add_screenshot(page,
                       text: "J'ouvre le menu des plages d'ouvertures pour renseigner mes disponibilités",
                       wait_for: "Vous n'avez pas encore créé de plage d'ouverture.")

    click_on "Renseigner mes disponibilités"

    find(:label, text: "Répéter…").click

    find(:label, text: "Suivi de dossier").click

    find(:label, text: "Mercredi").click
    find(:label, text: "Jeudi").click

    doc.add_screenshot(page,
                       text: "J'ouvre des créneaux aux horaires qui m'arrangent, par exemple les mercredi et jeudi matin.")

    click_on "Créer la plage d'ouverture"

    expect(page).to have_content "Plage d'ouverture créée"
    click_on "Configuration"

    doc.add_screenshot(page, text: "J'ouvre le menu de configuration", wait_for: "Réservation en ligne")

    click_on "Réservation en ligne"

    doc.add_screenshot(page, text: "J'ouvre le menu de réservation en ligne", wait_for: "Permettez à vos usagers de prendre rendez-vous en ligne")

    click_on "modifier"

    doc.add_screenshot(page,
                       text: "Je clique sur modifier à côté du nom du motif pour l'ouvrir à la réservation en ligne",
                       wait_for: "Définissez quel utilisateur peut prendre rendez-vous pour ce motif :")

    find(:label, text: "Agents de l’organisation, prescripteurs et usagers").click

    doc.add_screenshot(page,
                       text: "Je sélectionne la bonne option, et je confirme",
                       wait_for: "Définissez quel utilisateur peut prendre rendez-vous pour ce motif :")

    click_on "Enregistrer"

    expect(page).to have_content("Le motif Suivi de dossier a été modifié.")

    visit admin_organisation_online_booking_url(Organisation.last, host: "http://www.rdv-mairie-test.localhost")

    doc.add_screenshot(page,
                       text: "Je retourne sur la page de configuration de la prise de rendez-vous en ligne",
                       wait_for: "Permettez à vos usagers de prendre rendez-vous en ligne")

    find(:label, text: "des particuliers").click
    find(:label, text: "des professionnels").click
    click_on "Enregistrer"

    doc.add_screenshot(page,
                       text: "Je sélectionne la prise de rendez-vous par des professionnels et j'enregistre.",
                       wait_for: "Configuration mise à jour")

    doc.add_text("Je transmets le lien de prise de rendez-vous à un de mes usagers")

    doc.start_section("Côté usager")

    visit public_link_to_org_url(organisation_id: Organisation.last.id, host: "http://www.rdv-mairie-test.localhost/")

    doc.add_screenshot(page,
                       text: "Je visite le lien de prise de rendez-vous que l'agent m'a transmis.",
                       wait_for: "Sélectionnez le motif")

    click_on "Suivi de dossier"

    doc.add_screenshot(page,
                       text: "Je choisis un créneau",
                       wait_for: "Sélectionnez un créneau")

    click_on "9:00", match: :first

    doc.add_screenshot(page,
                       text: "L'appli me propose de me connecter avec ProConnect",
                       wait_for: "Vous devez vous connecter ou vous inscrire pour continuer.")

    # On triche pour faire semblant de faire une connexion via ProConnect
    user = create(:user, pro_connect_openid_sub: "fake_sub", first_name: "Camille", last_name: "Exemple", email: "camille.exemple@demo-rdv-service-public.gouv.fr")
    login_as(user, scope: :user)
    find("a[title='Modifier la date du rendez-vous']").click
    click_on "9:00", match: :first

    doc.add_screenshot(page,
                       text: "Mon nom et prénom sont remplis automatiquement, je continue",
                       wait_for: "Vos informations")

    click_on "Continuer"

    doc.add_screenshot(page,
                       text: "Je confirme le rendez-vous",
                       wait_for: user.email)

    click_on "Confirmer mon RDV"

    doc.add_screenshot(page,
                       text: "Le rendez-vous est pris, et les deux agents ont reçu un email de confirmation",
                       wait_for: "Votre rendez vous a été confirmé.")
  end
end
