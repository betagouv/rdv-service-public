RSpec.describe "Ouverture d'un espace", js: true do
  let!(:agent) { create(:agent, email: "test-admin@example.com", proconnect_siret:) }
  let!(:operator) { create(:operator, siret: operator_siret) }
  let(:operator_siret) { "13002603200016" }
  let(:proconnect_siret) { "21550050500015" }

  stub_env_with(ESPACE_OPERATEUR_ANCT_AUTH_TOKEN: "Bearer fake-token")

  before do
    login_as(agent, scope: :agent)
  end

  context "pour un agent qui est considéré comme admin de sa collectivité par l'espace opérateur" do
    around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_admin") { ex.run } }

    specify do
      doc = Autodoc.start_scenario("4) Ouverture automatique d'un espace pour une collectivité", self, category: "1) Ouverture d'espace")

      doc.start_section("Pour une collectivité avec un OPSN")
      doc.add_text("Contexte: Je suis un agent qui n'a jamais utilisé RDV Service Public. \
                 Je viens de me ProConnecter pour la première fois. Je suis rattaché à un OPSN qui m'autoriser à créer ou rejoindre un compte.")

      visit "http://www.rdv-service-public-test.localhost/"
      doc.add_screenshot(page,
                         text: "Mon espace est ouvert automatiquement.",
                         wait_for: "Bienvenue sur votre espace RDV Service Public")

      expect(agent.reload.organisations.first).to have_attributes(name: "Bezonvaux")
    end
  end

  context "pour un agent qui est reconnu par l'espace opérateur mais pas admin de son organisation" do
    around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_success") { ex.run } }

    let!(:agent) { create(:agent, email: "contact@mairie-nantes.fr", proconnect_siret:) }

    specify do
      doc = Autodoc.start_scenario("5) Agent non admin d'une collectivité", self, category: "1) Ouverture d'espace")

      doc.start_section("Pour une collectivité avec un OPSN")
      doc.add_text("Contexte: Je suis un agent qui n'a jamais utilisé RDV Service Public. \
                 Je viens de me ProConnecter pour la première fois. Je suis rattaché à un OPSN qui m'autoriser à créer ou rejoindre un compte.")

      visit "http://www.rdv-service-public-test.localhost/"
      doc.add_screenshot(page,
                         text: "On me dit de me rapprocher de mon admin.",
                         wait_for: "Votre organisation est rattachée à un espace RDV Service Public, mais vous n'avez pas les droits d'administrateur.")
    end
  end

  context "pour un agent reconnu par l'espace opérateur mais avec plusieurs opérateurs potentiels" do
    around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_with_potential_operators") { ex.run } }

    let!(:agent) { create(:agent, email: "contact@mairie-nantes.fr", proconnect_siret:) }
    let(:proconnect_siret) { "20005671100019" }

    specify do
      doc = Autodoc.start_scenario("5) Agent avec plusieurs opérateurs possibles", self, category: "1) Ouverture d'espace")

      doc.start_section("Pour une collectivité avec plusieurs OPSN potentiels")
      doc.add_text("Contexte: Je suis un agent qui n'a jamais utilisé RDV Service Public. \
                 Je viens de me ProConnecter pour la première fois. Je suis rattaché à plusieurs OPSN.")

      visit "http://www.rdv-service-public-test.localhost/"
      doc.add_screenshot(page,
                         text: "On me dit de me rapprocher de mon opérateur.",
                         wait_for: "Votre organisation est rattachée à l'opérateur ANCT, qui gère votre accès à RDV Service Public.")
    end
  end
end
