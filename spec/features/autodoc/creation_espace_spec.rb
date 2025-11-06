# Les captures d'écran des emails dans autodoc causent des erreurs JS à cause d'images qui ne chargent pas correctement
# donc on désactive cette vérification pour ces specs
RSpec.describe "Ouverture d'un espace", ignore_js_errors: true, js: true do
  let!(:agent) { create(:agent, first_name: "Francis", last_name: "Factice", password: "c0rrecThorse!") }

  around { |example| perform_enqueued_jobs { example.run } }

  specify do
    doc = Autodoc.start_scenario("2) Ouverture d'un espace avec validation", self, accessibility_checks: false, category: "1) Ouverture d'espace")

    doc.start_section("Côté agent")
    doc.add_text("Contexte: Je suis un agent qui n'a jamais utilisé RDV Service Public")

    visit "http://www.rdv-mairie-test.localhost/"
    doc.add_screenshot(page,
                       text: "Je clique sur 'Ouvrir un espace'",
                       wait_for: "Ouvrir un espace")

    click_on "Ouvrir un espace"
    doc.add_screenshot(page,
                       text: "Une page m'explique qu'il faut que je me ProConnecte.",
                       wait_for: "Pour ouvrir votre espace, commencez par vous identifier avec ProConnect.")

    # ProConnect ne marche pas en tests, donc on triche en faisant un login par email et mot de passe
    visit new_agent_session_path
    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: agent.password
    click_on "Se connecter"

    doc.add_screenshot(page,
                       text: "Je clique sur Demander à ouvrir un espace",
                       wait_for: "Pour commencer, aidez-nous à en savoir plus")

    click_on "Demander à ouvrir un espace"

    doc.add_screenshot(page, wait_for: "Nom de")

    fill_in("Nom de votre première organisation", with: "CCAS de Montreuil")

    doc.add_screenshot(page,
                       text: "Je remplis le formulaire puis je valide")

    click_on "Envoyer la demande"

    doc.add_screenshot(page,
                       text: "L'équipe déploiement a ensuite reçu la demande de création de compte dans le super admin",
                       wait_for: "Votre demande a bien été enregistrée.")

    doc.start_section("Côté super admin")

    super_admin = create :super_admin

    create(:service, name: "Service social")

    login_as(super_admin, scope: :super_admin)

    visit super_admins_territory_creation_requests_url(host: "http://www.rdv-mairie-test.localhost")

    doc.add_screenshot(page,
                       text: "Je consulte la liste des demandes d'ouverture d'espace",
                       wait_for: "CCAS de Montreuil")

    click_on "CCAS de Montreuil"

    doc.add_screenshot(page,
                       text: "J'examine la demande. C'est à cette étape que je peux avoir des informations sur des doublons potentiels",
                       wait_for: "Accepter")

    click_on "Accepter"

    select "Commune", from: "Catégorie de l'espace"

    select "Service social", from: "Service"
    doc.add_screenshot(page,
                       text: "Je remplis le formulaire puis je valide")

    click_on "Enregistrer"

    doc.add_screenshot(page,
                       text: "J'ai un message de confirmation",
                       wait_for: "Le nouvel espace a été créé")

    doc.start_section("Côté agent")
    open_email(agent.email)
    expect(current_email.subject).to eq "Votre espace RDV Service Public est ouvert 🚀"

    doc.add_screenshot(current_email, text: "J'ai un message de confirmation. Je clique sur le cta principal")

    current_email.click_on "Accéder à mon espace"

    doc.add_screenshot(page,
                       text: "J'arrive dans mon espace")
  end
end
