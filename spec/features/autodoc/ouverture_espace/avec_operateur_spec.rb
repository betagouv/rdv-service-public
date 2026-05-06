RSpec.describe "Ouverture d'un espace", js: true do
  let!(:agent) { create(:agent, email: "test-admin@example.com", proconnect_siret:) }
  let!(:operator) { create(:operator, siret: operator_siret) }
  let(:operator_siret) { "13002603200016" }
  let(:proconnect_siret) { "21550050500015" }

  stub_env_with(ESPACE_OPERATEUR_ANCT_AUTH_TOKEN: "Bearer fake-token")

  around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_admin") { ex.run } }

  before do
    login_as(agent, scope: :agent)
  end

  specify do
    doc = Autodoc.start_scenario("4) Ouverture d'un espace pour une collectivité", self, category: "1) Ouverture d'espace")

    doc.start_section("Pour une collectivité avec un OPSN")
    doc.add_text("Contexte: Je suis un agent qui n'a jamais utilisé RDV Service Public. \
                 Je viens de me ProConnecter pour la première fois. Je suis rattaché à un OPSN qui m'autoriser à créer ou rejoindre un compte.")

    visit "http://www.rdv-service-public-test.localhost/"
    doc.add_screenshot(page,
                       text: "Mon espace est ouvert automatiquement.",
                       wait_for: "Bienvenue sur votre espace RDV Service Public")
  end
end
