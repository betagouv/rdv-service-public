RSpec.describe Agents::PagesController, type: :controller do
  describe "#home" do
    let(:agent) { create(:agent) }

    before do
      sign_in agent
    end

    context "quand l’agent n’a pas d’organisation accessible" do
      it "rend la page d’accueil" do
        get :home
        expect(response).to render_template("home")
      end

      context "et que l’agent peut créer un territory (email vérifié)" do
        let(:agent) { create(:agent, email: "agent@example.gouv.fr") }

        context "sans organisations doublons possibles" do
          it "redirige vers la création d’un territory" do
            get :home
            expect(response).to redirect_to(new_agents_territory_path)
          end
        end

        context "avec des organisations doublons possibles" do
          before do
            other_agent = create(:agent, email: "other@example.gouv.fr")
            create(:organisation, agents: [other_agent])
          end

          it "redirige vers la demande d’ouverture de compte" do
            get :home
            expect(response).to redirect_to(new_agents_territory_creation_request_path)
          end
        end
      end
    end

    context "quand l’agent a une seule organisation accessible" do
      let(:organisation) { create(:organisation) }

      before do
        agent.organisations << organisation
      end

      it "redirige l’agent vers l’agenda de l’organisation" do
        get :home
        expect(response).to redirect_to(admin_organisation_planning_agenda_path(organisation))
      end
    end

    context "quand l’agent a plusieurs organisations accessibles" do
      let(:organisation1) { create(:organisation) }
      let(:organisation2) { create(:organisation) }
      let(:agent) { create(:agent, admin_role_in_organisations: [organisation1, organisation2]) }

      it "redirige l’agent vers la liste des organisations" do
        get :home
        expect(response).to redirect_to(admin_organisations_path)
      end
    end
  end
end
