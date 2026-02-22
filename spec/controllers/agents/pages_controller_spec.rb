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
    end

    context "quand l’agent a une seule organisation accessible" do
      let!(:organisation) { organisations(:default_org) }

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
