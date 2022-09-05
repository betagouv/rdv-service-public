# frozen_string_literal: true

describe Admin::RdvsCollectifs::MotifsController, type: :controller do
  describe "GET index" do
    context "with a signed in agent" do
      let(:organisation) { create(:organisation) }
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before { sign_in agent }

      it "returns success" do
        get :index, params: { organisation_id: organisation.id }

        expect(response).to be_successful
      end

      context "when there is no collective Motif" do
        render_views

        it "shows a message indicating that there is no collective Motif" do
          get :index, params: { organisation_id: organisation.id }

          expect(response.body).to include("Il n'existe aucun motif de RDV collectif")
        end

        context "when the current agent can create a Motif" do
          let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

          it "shows a button to create a Motif" do
            get :index, params: { organisation_id: organisation.id }

            expect(response.body).to include("Créer un motif")
            expect(response.body).not_to include("Demandez à un administrateur")
          end
        end

        context "when the current agent can't create a Motif" do
          it "shows a message indicating that they should ask for help" do
            get :index, params: { organisation_id: organisation.id }

            expect(response.body).not_to include("Créer un motif")
            expect(response.body).to include("Demandez à un administrateur")
          end
        end
      end
    end
  end
end
