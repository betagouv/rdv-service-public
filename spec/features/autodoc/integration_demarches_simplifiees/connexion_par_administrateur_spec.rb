RSpec.describe "Connexion de Démarches Simplifiées à RDV Service Public par un admin", js: true do
  let!(:agent) do
    create(:agent, :francis_factice, password: "RdvServicePublicTest1!")
  end
  let(:oauth_application) do
    create(:oauth_application, name: "Démarches Simplifiées",
                               logo_base64: file_fixture("logo_demarches_simplifiees_base_64.txt").read)
  end

  around do |example|
    previous_host = Capybara.app_host
    Capybara.app_host = "http://www.rdv-service-public-test.localhost:#{previous_host[/\d+/]}"
    example.run
    Capybara.app_host = previous_host
  end

  # On fait quelque chose d'un peu inhabituel dans cette spec pour avoir un test d'intégration sur l'oauth
  # dans un contexte où notre application est le fournisseur d'oauth : on démarre une petite application
  # Sinatra qui joue le rôle d'une application externe (comme Démarches Simplifiées) qui propose un
  # oauth vers notre appli.
  stub_env_for_proconnect

  specify do
    doc = Autodoc.start_scenario("1) Connexion de à RDV Service Public par un admin", self, category: "4) Intégration à Démarches Simplifiées")

    login_as(agent, scope: :agent)

    visit oauth_authorization_path(
      client_id: oauth_application.uid,
      redirect_uri: oauth_application.redirect_uri.split("\n").first, response_type: :code, scope: :write, state: "fakestate"
    )
    doc.start_section("Connexion initiale")

    # Si je ne suis pas connecté, je me fais rediriger vers le /authorize de ProConnect pour le silent login
    # Pour simplifier cette spec, on s'est connecté au préalable

    doc.add_text <<~TEXT
      Depuis Démarches Simplifiées, l'administrateur connecte RDV Service Public.
      Il n'a pas besoin d'avoir un compte sur RDV Service Public : il peut directement utiliser ProConnect.
    TEXT

    doc.add_screenshot(page,
                       text: "On me demande de confirmer que j'accepte de connecter les deux applications.",
                       wait_for: "vous allez permettre à Démarches Simplifiées")

    doc.add_text("Je suis ensuite redirigé vers Démarches Simplifiées.")
  end
end
