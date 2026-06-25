RSpec.describe "OAuth provider", js: true do
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

  stub_env_with(
    RDV_SERVICE_PUBLIC_OAUTH_BASE_URL: "http://localhost:#{Capybara.server_port}",
    RDV_SERVICE_PUBLIC_OAUTH_APP_ID: "fake_app_id",
    RDV_SERVICE_PUBLIC_OAUTH_APP_SECRET: "fake_app_secret",
    PRO_CONNECT_DISABLED: "true" # Pour simplifier la connexion dans les tests, on fait une connexion par email/mot de passe
  )

  let!(:agent) do
    create(:agent, email: "francis@factice.org", password: "RdvServicePublicTest1!")
  end

  before do
    application = Doorkeeper::Application.new(
      name: "Démarches Simplifiées",
      uid: "fake_app_id",
      redirect_uri: "http://localhost:4567/omniauth/rdvservicepublic/callback",
      post_logout_redirect_uri: "http://localhost:4567/",
      logo_base64: ""
    )

    application.secret_strategy.store_secret(application, :secret, "fake_app_secret")
    application.save!
  end

  specify "Parcours complet" do
    visit "http://localhost:4567/"
    click_button "Se connecter avec RDV Service Public"

    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: agent.password
    click_on "Se connecter"

    expect(page).to have_content("En continuant, vous allez permettre à Démarches Simplifiées d'accéder à votre compte RDV Solidarités")
    click_on "Continuer"
    expect(page).to have_content("Votre email est francis@factice.org")

    expect(Doorkeeper::AccessToken.last.refresh_token).to be_present

    click_on "Déconnexion"

    # On est déconnecté du client et de RDV Service Public
    expect(page).to have_content("Se connecter avec RDV Service Public")
    expect(page).to have_current_path("/")

    visit "/"
    expect(page).not_to have_content "Déconnexion réussie" # On n'affiche pas le flash sur la visite suivante

    # La fois suivante, il y a uniquement besoin de se connecter, pas de reconfirmer qu'on donne la permission à l'appli
    # Et on peut se connecter avant de faire l'oauth
    click_on "Connexion Agent"
    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: agent.password
    click_on "Se connecter"
    expect(page).to have_content("Pour commencer, aidez-nous à en savoir plus :")

    visit "http://localhost:4567/"
    click_button "Se connecter avec RDV Service Public"

    expect(page).to have_content("Votre email est francis@factice.org")
    api_token = /votre token est (\S+),/.match(page.text)[1]
    refresh_token = /votre refresh_token est (\S+)/.match(page.text)[1]

    updated_token = nil
    updated_refresh_token = nil
    # On peut utiliser un client d'api avec ces tokens
    client = RdvServicePublicApiClient.new(
      api_token,
      refresh_token,
      on_token_refresh: lambda do |new_token, new_refresh_token|
        updated_token = new_token
        updated_refresh_token = new_refresh_token
      end
    )
    response = client.get("agents/me")
    expect(response.dig("agent", "email")).to eq "francis@factice.org"

    visit "http://localhost:4567/logout"

    # Le lendemain, il n'y a toujours pas besoin de reconfirmer la permission
    travel_to(1.day.from_now)
    CronJob::DestroyOldOauthObjects.perform_now

    visit "http://localhost:4567/"
    click_button "Se connecter avec RDV Service Public"

    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: agent.password
    click_on "Se connecter"

    expect(page).to have_content("Votre email est francis@factice.org")

    # Le client est capable de refresh son token
    response = client.get("agents/me")
    expect(response.dig("agent", "email")).to eq "francis@factice.org"

    expect(updated_token).not_to be_nil
    expect(updated_refresh_token).not_to be_nil
  end
end
