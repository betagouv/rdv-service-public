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
      logo_base64: "data:image/png;base64,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" # rubocop:disable Layout/LineLength
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
    doc.add_screenshot(page,
                       text: text,
                       wait_for: "Vous devez vous connecter pour continuer")

    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: agent.password
    click_on "Se connecter"

    doc.add_screenshot(page,
                       text: "On me demande de confirmer que j'accepte de connecter les deux applications.",
                       wait_for: "vous allez permettre à Démarches Simplifiées")

    doc.add_text <<~TEXT
      Je suis ensuite redirigé vers Démarches Simplifiées.
    TEXT
  end
end
