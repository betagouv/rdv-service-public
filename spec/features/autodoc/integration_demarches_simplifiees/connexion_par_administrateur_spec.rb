RSpec.describe "Connexion de Démarches Simplifiées à RDV Service Public par un admin", js: true do
  let!(:agent) do
    create(:agent, :francis_factice, password: "RdvServicePublicTest1!")
  end

  around do |example|
    previous_host = Capybara.app_host
    Capybara.app_host = "http://www.rdv-mairie-test.localhost:#{previous_host[/\d+/]}"
    example.run
    Capybara.app_host = previous_host
  end

  # On fait quelque chose d'un peu inhabituel dans cette spec pour avoir un test d'intégration sur l'oauth
  # dans un contexte où notre application est le fournisseur d'oauth : on démarre une petite application
  # Sinatra qui joue le rôle d'une application externe (comme Démarches Simplifiées) qui propose un
  # oauth vers notre appli.
  around do |example|
    pid = Process.fork do
      OmniAuth.config.test_mode = false

      `touch log/test_sinatra.log`
      $stdout.reopen("log/test_sinatra.log", "r+") # Pour ne pas logger sur stdout
      FakeOauthClient.run!
    end

    example.run

    Process.kill("KILL", pid)
    Process.wait(pid) # pour éviter d'avoir un process zombie
  end

  stub_env_for_proconnect
  before do
    application = Doorkeeper::Application.new(
      name: "Démarches Simplifiées",
      uid: "fake_app_id",
      redirect_uri: "http://localhost:4567/omniauth/rdvservicepublic/callback",
      post_logout_redirect_uri: "http://localhost:4567/",
      logo_base64: file_fixture("logo_demarches_simplifiees_base_64.tx").read
    )

    application.secret_strategy.store_secret(application, :secret, "fake_app_secret")
    application.save!
  end

  specify do
    doc = Autodoc.start_scenario("Connexion de Démarches Simplifiées à RDV Service Public par un admin", self)

    visit "http://localhost:4567/"
    click_button "Se connecter avec RDV Service Public"

    doc.start_section("Connexion initiale")

    doc.add_text <<~TEXT
      Depuis Démarches Simplifiées, l'administrateur connecte RDV Service Public.
      Il n'a pas besoin d'avoir un compte sur RDV Service Public : il peut directement utiliser ProConnect.
    TEXT

    text = <<~TEXT
      Je peux me connecter avec ProConnect même si je n'ai jamais utilisé RDV Service Public.
      Si j'ai déjà un compte, je peux aussi me connecter par email et mot de passe.
      Si je suis déjà connecté à RDV Service Public, cet écran ne s'affiche pas et je passe directement au suivant.
    TEXT
    doc.add_screenshot(page, text: text, wait_for: "Vous devez vous connecter pour continuer")

    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: agent.password
    click_on "Se connecter"

    doc.add_screenshot(page,
                       text: "On me demande de confirmer que j'accepte de connecter les deux applications.",
                       wait_for: "vous allez permettre à Démarches Simplifiées")

    doc.add_text("Je suis ensuite redirigé vers Démarches Simplifiées.")
  end
end
