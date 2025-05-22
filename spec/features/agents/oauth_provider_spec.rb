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

  let!(:agent) do
    create(:agent, email: "francis@factice.org", password: "Rdvservicepublictest1!")
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

    expect(page).to have_content("Vous devez vous connecter pour continuer")
    find(".fr-alert--info") # On vérifie que le flash est une info et pas une alerte

    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: agent.password
    click_on "Se connecter"

    expect(page).to have_content("Connexion réussie")
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
    click_on "Espace Agent"
    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: agent.password
    click_on "Se connecter"
    expect(page).to have_content("Connexion réussie")

    visit "http://localhost:4567/"
    click_button "Se connecter avec RDV Service Public"

    expect(page).to have_content("Votre email est francis@factice.org")

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

    visit "http://localhost:4567/logout"

    # Un mois plus tard, si on ne s'est pas reconnecté, il faut à nouveau donner la permission à l'application
    travel_to(31.days.from_now)
    CronJob::DestroyOldOauthObjects.perform_now

    visit "http://localhost:4567/"
    click_button "Se connecter avec RDV Service Public"

    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: agent.password
    click_on "Se connecter"

    expect(page).to have_content("Connexion réussie")
    expect(page).to have_content("En continuant, vous allez permettre à Démarches Simplifiées d'accéder à votre compte RDV Solidarités")
    expect(page).to have_content(agent.email) # On indique à l'agent le compte utilisé pour la connexion
    click_on "Continuer"

    expect(page).to have_content("Votre email est francis@factice.org")
  end
end
