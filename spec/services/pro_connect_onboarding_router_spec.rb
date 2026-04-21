RSpec.describe ProConnectOnboardingRouter do
  subject(:handler) { described_class.new(agent, domain) }

  let(:domain) { Domain::RDV_SERVICE_PUBLIC }
  let(:operator_siret) { "13002603200016" }
  let(:proconnect_siret) { "21550050500015" }
  let(:agent) { create(:agent, email: "test-admin@example.com", proconnect_siret:) }

  stub_env_with(ESPACE_OPERATEUR_ANCT_AUTH_TOKEN: "Bearer fake-token")

  describe "#call" do
    context "quand l'agent a un email d'un domaine de l'État" do
      let(:agent) { create(:agent, email: "agent@etat.gouv.fr") }

      it "retourne :classic sans appeler l'API" do
        expect(EspaceOperateurANCT).not_to receive(:new)
        expect(handler.call.action).to eq(:classic)
      end
    end

    context "quand l'agent n'a pas de SIRET ProConnect" do
      let(:agent) { create(:agent, proconnect_siret: nil) }

      it "retourne :classic sans appeler l'API" do
        expect(EspaceOperateurANCT).not_to receive(:new)
        expect(handler.call.action).to eq(:classic)
      end
    end

    context "quand l'API ANCT échoue (token absent)" do
      stub_env_with(ESPACE_OPERATEUR_ANCT_AUTH_TOKEN: nil)

      it "retourne :classic et capture l'exception dans Sentry" do
        expect { handler.call }.to change(sentry_events, :size).by(1)
        expect(sentry_events.last.exception.values.first.value).to eq("Ce service n’est pas utilisable dans cet environnement. (RuntimeError)")
        expect(handler.call.action).to eq(:classic)
      end
    end

    context "l'API retourne un opérateur qui matche un Operator de notre DB" do
      let!(:operator) { create(:operator, siret: operator_siret) }

      context "et l'agent est admin" do
        let(:agent) { create(:agent, email: "test-admin@example.com", proconnect_siret:) }

        around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_admin") { ex.run } }

        it "retourne :attached_as_admin" do
          expect(handler.call.action).to eq(:attached_as_admin)
        end

        context "quand l'organisation a déjà un territoire avec une organisation" do
          let!(:territory) { create(:territory, operator: operator, siret: proconnect_siret) }
          let!(:organisation) { create(:organisation, territory: territory) }

          it "rattache l'agent à l'organisation et au territoire existants sans créer de nouveaux records" do
            expect { handler.call }
              .to change(AgentRole, :count).by(1)
              .and change(AgentTerritorialRole, :count).by(1)
              .and change(AgentTerritorialAccessRight, :count).by(1)

            expect(Territory.count).to eq(1)
            expect(Organisation.count).to eq(1)
            expect(AgentRole.last).to have_attributes(agent: agent, organisation: organisation, access_level: "admin")
            expect(AgentTerritorialRole.last).to have_attributes(agent: agent, territory: territory)
            expect(AgentTerritorialAccessRight.last).to have_attributes(
              agent: agent, territory: territory,
              allow_to_manage_access_rights: true,
              allow_to_invite_agents: true
            )
          end
        end

        context "quand l'organisation a un territoire sans organisation" do
          let!(:territory) { create(:territory, operator: operator, siret: proconnect_siret) }

          it "crée une organisation et rattache l'agent sans créer de nouveau territoire" do
            expect { handler.call }.to change(Organisation, :count).by(1)

            organisation = Organisation.last
            expect(organisation.name).to eq("Bezonvaux") # nom retourné par la cassette VCR
            expect(organisation.territory).to eq(territory)
          end
        end

        context "quand l'organisation n'a pas encore de territoire" do
          it "crée un territoire vide et une organisation" do
            expect { handler.call }
              .to change(Territory, :count).by(1)
              .and change(Organisation, :count).by(1)

            territory = Territory.last
            expect(territory.operator).to eq(operator)
            expect(territory.name).to be_nil
            expect(territory.category).to eq("Inconnu") # la cassette VCR retourne type "other"
            expect(territory.siret).to eq(proconnect_siret)

            organisation = Organisation.last
            expect(organisation.name).to eq("Bezonvaux")
          end
        end
      end

      context "et l'agent a accès mais n'est pas admin" do
        let(:agent) { create(:agent, email: "contact@mairie-nantes.fr", proconnect_siret:) }

        around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_success") { ex.run } }

        it "retourne :contact_admin sans créer de territoire" do
          result = handler.call
          expect(result.action).to eq(:contact_admin)
          expect(Territory.count).to eq(0)
          expect(Organisation.count).to eq(0)
        end
      end
    end

    context "l'API retourne des potentialOperators dont un matche un Operator de notre DB" do
      let(:agent) { create(:agent, email: "contact@mairie-nantes.fr", proconnect_siret: "20005671100019") }
      let!(:operator) { create(:operator, siret: "13002603200016") } # SIRET du premier potentialOperator dans la cassette

      around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_with_potential_operators") { ex.run } }

      it "retourne :signup_via_operator avec le signupUrl et le nom de l'opérateur" do
        result = handler.call
        expect(result.action).to eq(:signup_via_operator)
        expect(result.signup_url).to eq("https://suiteterritoriale.anct.gouv.fr/deep-link-signup/")
        expect(result.operator_name).to eq("ANCT")
      end

      it "ne crée pas de territoire" do
        handler.call
        expect(Territory.count).to eq(0)
      end
    end

    context "plusieurs potentialOperators matchent notre DB" do
      let(:agent) { create(:agent, email: "contact@mairie-nantes.fr", proconnect_siret: "20005671100019") }
      let!(:operator_1) { create(:operator, siret: "13002603200016") }
      let!(:operator_2) { create(:operator, siret: "12345678901234") }

      around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_with_potential_operators") { ex.run } }

      it "envoie un message Sentry" do
        expect(Sentry).to receive(:capture_message).with(
          "ProConnectOnboardingRouter: plusieurs potentialOperators matchent notre DB",
          extra: { agent_id: agent.id, sirets: %w[13002603200016 12345678901234] }
        )
        handler.call
      end

      it "retourne quand même :signup_via_operator avec le premier match" do
        allow(Sentry).to receive(:capture_message)
        result = handler.call
        expect(result.action).to eq(:signup_via_operator)
        expect(result.operator_name).to eq("ANCT")
      end
    end

    context "l'API retourne des potentialOperators mais aucun ne matche notre DB" do
      let(:agent) { create(:agent, email: "contact@mairie-nantes.fr", proconnect_siret: "20005671100019") }

      around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_with_potential_operators") { ex.run } }

      it "retourne :classic" do
        expect(handler.call.action).to eq(:classic)
      end
    end

    context "l'API retourne un opérateur mais le SIRET ne matche pas notre DB" do
      around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_success") { ex.run } }

      it "retourne :classic" do
        expect(handler.call.action).to eq(:classic)
      end
    end
  end
end
