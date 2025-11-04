RSpec.describe "Prise de rendez-vous entre agents", js: true do
  let(:service) { create(:service, name: "Dinum", short_name: "Dinum") }

  stub_env_for_proconnect
  stub_env_with(
    FRANCECONNECT_V2_BASE_URL: "https://fcp-low.sbx.dev-franceconnect.fr/api/v2",
    FRANCECONNECT_V2_CLIENT_ID: "fake_france_connect_v2_client_id",
    FRANCECONNECT_V2_CLIENT_SECRET: "fake_france_connect_v2_client_secret"
  )
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

    create(:motif, organisation: Organisation.last, location_type: :visio, name: "Suivi de dossier", bookable_by: :agents)
  end

  specify do
    agent = Agent.find_by(first_name: "Francis")
    agent.update!(confirmed_at: 10.days.ago)

    login_as(agent, scope: :agent)

    doc = Autodoc.start_scenario("Prise de rendez-vous entre agents", self, accessibility_checks: false)

    doc.start_section("Côté agent")
    doc.add_text(<<~TEXT
      <h3>Contexte</h3>
      <p>
        Je souhaite proposer de la prise de rendez-vous à d'autres agents du service public, en leur envoyant un lien avec lequel ils pourront directement prendre rendez-vous.
      </p>
      <p>
        RDV Service Public peut remplacer des solutions de type Cal.com pour la prise de rendez-vous entre agents de différentes structures.
      </p>
      <p>
        Pour une réunion entre collègues, la prise de rendez-vous via votre calendrier partagé habituel reste plus pratique (par exemple la Suite Numérique, Outlook, Thunderbird…). Si vous avez besoin de proposer des rendez-vous à d'autres agents qui ne sont pas vos collègues, RDV Service Public peut vous aider.
      </p>
      <h3>
        Exemple de cas d’usage
      </h3>
      <p>
        Vous faites partie de l’équipe produit d’un service public numérique.
        Vous souhaitez proposer des entretiens utilisateurs aux agents de mairie qui utilisent votre service.
        Voici comment vous pouvez faire :
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

    doc.add_screenshot(page, text: "J'ouvre le menu de configuration et je clique sur la Réservation en ligne", wait_for: "Réservation en ligne")

    click_on "Réservation en ligne"

    doc.add_screenshot(page, text: "Je sélectionne mon motif et je valide", wait_for: "Vous gardez le contrôle")

    find("label", text: "Suivi de dossier").click

    click_on "Enregistrer"

    doc.add_screenshot(page, text: "Je clique sur Modifier dans la carte de Profil des usagers", wait_for: "Lien de réservation")

    click_on "Modifier", match: :first

    find(:label, text: "des particuliers").click
    find(:label, text: "des professionnels").click

    doc.add_screenshot(page,
                       text: "Je sélectionne la prise de rendez-vous par des professionnels et j'enregistre.",
                       wait_for: "Qui participe aux rendez-vous avec les agents de votre organisation ?")

    click_on "Enregistrer"

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

    expect(page).not_to have_content("FranceConnect")

    expect(page).to have_content("ProConnect")
    # On triche pour faire semblant de faire une connexion via ProConnect
    user = create(:user, pro_connect_openid_sub: "fake_sub", first_name: "Camille", last_name: "Exemple",
                         email: nil, encrypted_password: "",
                         phone_number: nil,
                         notification_email: "camille.exemple@demo-rdv-service-public.gouv.fr")
    login_as(user, scope: :user)
    find("a[title='Modifier la date du rendez-vous']").click
    click_on "9:00", match: :first

    doc.add_screenshot(page,
                       text: "Mon nom et prénom sont remplis automatiquement, je continue",
                       wait_for: "Vos informations")

    expect(page.body).to include(user.notification_email) # L'email est dans un input, donc on utilise cette méthode plutôt qu'un expect(page).to have_content

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
