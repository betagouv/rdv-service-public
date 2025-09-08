RSpec.describe "Migration depuis RDV Aide Numérique vers RDV Service Public", js: true do
  around { |example| perform_enqueued_jobs { example.run } }

  around do |example|
    previous_mode = OmniAuth.config.test_mode

    OmniAuth.config.test_mode = false # On fait un vrai parcours d'oauth

    example.run

    OmniAuth.config.test_mode = previous_mode
  end

  # Pour simplifier les test, on crée deux agents sur la même instance
  let(:organisation_rdv_aide_num) { create(:organisation, name: "France Service de Montreuil") }
  let!(:agent_rdv_aide_num) do
    create(:agent, first_name: "Camille", last_name: "Clavier", admin_role_in_organisations: [organisation_rdv_aide_num])
  end

  let!(:users) do
    create_list(:user, 3, organisations: [organisation_rdv_aide_num])
  end

  let!(:agent_rdv_sp) do
    create(:agent, first_name: "Camille", last_name: "Clavier", password: "c0rrecThorse!", admin_role_in_organisations: [])
  end

  let!(:oauth_application) do
    application = OauthApplication.new(
      name: "RDV Aide Numérique",
      uid: "fake-app-id",
      redirect_uri: "http://www.rdv-aide-numerique-test.localhost/omniauth/rdvservicepublic/callback",
      logo_base64: ""
    )

    application.secret_strategy.store_secret(application, :secret, "fake-app-secret")
    application.save!

    application
  end

  stub_env_for_proconnect
  stub_env_with(
    RDV_SERVICE_PUBLIC_OAUTH_APP_ID: "fake-app-id",
    RDV_SERVICE_PUBLIC_OAUTH_APP_SECRET: "fake-app-secret",
    RDV_SERVICE_PUBLIC_OAUTH_BASE_URL: "http://localhost:#{Capybara.server_port}"
  )

  specify do
    doc = Autodoc.start_scenario("Migration depuis RDV Aide Numérique vers RDV Service Public", self)

    doc.start_section("Migration")
    doc.add_text(<<~TEXT
      Dans un premier temps, cette fonctionnalité n'est accessible que en ayant directement l'url.
      On va la communiquer aux beta testeurs, et on pourra ensuite la rendre accessible depuis le menu des paramètres.
    TEXT
                )

    login_as(agent_rdv_aide_num, scope: :agent)
    visit "http://www.rdv-aide-numerique-test.localhost/agents/instance_exports"

    doc.add_screenshot(page,
                       text: "J'ouvre la page à https://www.rdv-aide-numerique.fr/agents/instance_exports, puis je clique sur le bouton pour commencer",
                       wait_for: "Migration vers RDV Service Public")

    click_on "Commencer"

    doc.add_screenshot(page,
                       text: "On m'explique l'étape suivante. Je clique sur le bouton de connexion",
                       wait_for: "Pour commencer")

    # On triche un peu pour simuler la connexion à RDV SP
    visit "http://#{Domain::RDV_MAIRIE.host_name}/agents/sign_in"

    doc.add_screenshot(page,
                       text: "Je me connecte sur RDV Service Public",
                       wait_for: "Connexion agent à RDV Service Public")

    # Et on triche à nouveau pour faire le callback d'oauth
    # en imitant le code de Agents::InstanceExportsController#oauth_callback

    rdv_sp_token = create(:access_token, resource_owner_id: agent_rdv_sp.id, application: oauth_application)

    instance_export = InstanceExport.create!(
      agent: agent_rdv_aide_num,
      api_token: rdv_sp_token.plaintext_token,
      refresh_token: rdv_sp_token.refresh_token
    )

    visit "http://www.rdv-aide-numerique-test.localhost/admin/organisations/#{organisation_rdv_aide_num.id}/instance_exports/#{instance_export.id}/new_organisation"

    doc.add_screenshot(page,
                       text: "Je suis redirigé vers RDV Aide Numérique, on m'indique qu'on va créer une nouvelle organisation.",
                       wait_for: "Nous allons ouvrir un nouvel espace")

    click_on "Continuer"

    doc.add_screenshot(page,
                       text: "Je clique sur Copier les usagers",
                       wait_for: "Vous allez copier ")

    click_on "Copier les usagers"

    doc.add_screenshot(page,
                       text: "La migration est réussie. Mes usagers sont maintenant disponibles sur RDV Service Public",
                       wait_for: "Migration terminée")
  end
end
