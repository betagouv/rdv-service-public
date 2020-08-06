RSpec.describe Agents::PlageOuverturesController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:motif) { create(:motif, organisation: organisation) }
  let!(:lieu1) { create(:lieu, organisation: organisation, name: "MDS Sud", address: "10 rue Belsunce") }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu1, organisation: organisation, agent: agent) }

  shared_examples "agent can CRUD plage ouverture" do
    describe "GET #index" do
      it "returns a success response" do
        get :index, params: { organisation_id: organisation.id, agent_id: agent.id }
        expect(response).to be_successful
      end

      describe "format json" do
        let(:agent) { create(:agent, organisations: [organisation]) }
        let!(:plage_ouverture) { create(:plage_ouverture, :weekly_by_2, title: "Une semaine sur deux les mercredis à partir du 17/07", first_day: Date.new(2019, 7, 17), lieu: lieu1, agent: agent, organisation: organisation) }
        let!(:plage_ouverture2) { create(:plage_ouverture, :weekly, title: "Tous les lundis à partir du 22/07", first_day: Date.new(2019, 7, 22), lieu: lieu1, agent: agent, organisation: organisation) }
        let!(:plage_ouverture3) { create(:plage_ouverture, title: "Une seule fois le 24/07", first_day: Date.new(2019, 7, 24), lieu: lieu1, agent: agent, organisation: organisation) }
        let!(:plage_ouverture4) { create(:plage_ouverture, title: "Une seule fois le 24/07", first_day: Date.new(2019, 7, 24), lieu: lieu1, agent: agent, recurrence: Montrose::Recurrence.new, organisation: organisation) }

        before do
          sign_in agent
        end

        subject { get :index, params: { format: "json", organisation_id: organisation.id, agent_id: agent.id, start: start_date, end: end_date } }

        before do
          subject
          @parsed_response = JSON.parse(response.body)
        end

        context "from 08/07/2019 to 14/07/2019" do
          let(:start_date) { Date.new(2019, 7, 8) }
          let(:end_date) { Date.new(2019, 7, 14) }

          it { expect(response).to have_http_status(:ok) }
          it { expect(response.body).to eq("[]") }
        end

        context "from 22/07/2019 to 28/07/2019" do
          let(:start_date) { Date.new(2019, 7, 22) }
          let(:end_date) { Date.new(2019, 7, 28) }

          it "should return 3 occurences from plage_ouverture2 3 and 4" do
            expect(@parsed_response.size).to eq(3)

            first = @parsed_response[0]
            expect(first.size).to eq(6)
            expect(first["title"]).to eq(plage_ouverture2.title)
            expect(first["start"]).to eq(plage_ouverture2.starts_at.as_json)
            expect(first["end"]).to eq(plage_ouverture2.ends_at.as_json)
            expect(first["backgroundColor"]).to eq("#6fceff80")
            expect(first["rendering"]).to eq("background")
            expect(first["extendedProps"]).to eq({ lieu: "MDS Sud", location: "10 rue Belsunce" }.as_json)

            second = @parsed_response[1]
            expect(second.size).to eq(6)
            expect(second["title"]).to eq(plage_ouverture3.title)
            expect(second["start"]).to eq("2019-07-24T08:00:00.000+02:00")
            expect(second["end"]).to eq("2019-07-24T12:00:00.000+02:00")
            expect(second["backgroundColor"]).to eq("#6fceff80")
            expect(second["rendering"]).to eq("background")
            expect(second["extendedProps"]).to eq({ lieu: "MDS Sud", location: "10 rue Belsunce" }.as_json)

            third = @parsed_response[2]
            expect(third.size).to eq(6)
            expect(third["title"]).to eq(plage_ouverture4.title)
            expect(third["start"]).to eq("2019-07-24T08:00:00.000+02:00")
            expect(third["end"]).to eq("2019-07-24T12:00:00.000+02:00")
            expect(third["backgroundColor"]).to eq("#6fceff80")
            expect(third["rendering"]).to eq("background")
            expect(third["extendedProps"]).to eq({ lieu: "MDS Sud", location: "10 rue Belsunce" }.as_json)
          end
        end

        context "from 29/07/2019 to 04/08/2019" do
          let(:start_date) { Date.new(2019, 7, 29) }
          let(:end_date) { Date.new(2019, 8, 4) }

          it "should return two occurences one from plage_ouverture and one from plage_ouverture2" do
            expect(@parsed_response.size).to eq(2)

            first = @parsed_response[0]
            expect(first.size).to eq(6)
            expect(first["title"]).to eq(plage_ouverture2.title)
            expect(first["start"]).to eq("2019-07-29T08:00:00.000+02:00")
            expect(first["end"]).to eq("2019-07-29T12:00:00.000+02:00")
            expect(first["backgroundColor"]).to eq("#6fceff80")
            expect(first["rendering"]).to eq("background")
            expect(first["extendedProps"]).to eq({ lieu: plage_ouverture2.lieu.name, location: plage_ouverture2.lieu.address }.as_json)

            second = @parsed_response[1]
            expect(second.size).to eq(6)
            expect(second["title"]).to eq(plage_ouverture.title)
            expect(second["start"]).to eq("2019-07-31T08:00:00.000+02:00")
            expect(second["end"]).to eq("2019-07-31T12:00:00.000+02:00")
            expect(second["backgroundColor"]).to eq("#6fceff80")
            expect(second["rendering"]).to eq("background")
            expect(second["extendedProps"]).to eq({ lieu: plage_ouverture.lieu.name, location: plage_ouverture.lieu.address }.as_json)
          end
        end
      end
    end

    describe "GET #new" do
      it "returns a success response" do
        get :new, params: { organisation_id: organisation.id, agent_id: agent.id }
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns a success response" do
        get :edit, params: { organisation_id: organisation.id, id: plage_ouverture.to_param }
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      context "with valid params" do
        let(:valid_attributes) do
          plage_ouverture.attributes.merge(motif_ids: [plage_ouverture.motifs.last.id])
        end

        it "creates a new PlageOuverture" do
          expect do
            post :create, params: { organisation_id: organisation.id, plage_ouverture: valid_attributes }
          end.to change(PlageOuverture, :count).by(1)
        end

        it "redirects to the created plage_ouverture" do
          post :create, params: { organisation_id: organisation.id, plage_ouverture: valid_attributes }
          expect(response).to redirect_to(organisation_agent_plage_ouvertures_path(organisation, PlageOuverture.last.agent_id))
        end
      end

      context "with invalid params" do
        let(:invalid_attributes) do
          {
            agent_id: agent.id,
            title: "test plage_ouverture",
          }
        end

        it "does not create a new PlageOuverture" do
          expect do
            post :create, params: { organisation_id: organisation.id, plage_ouverture: invalid_attributes }
          end.not_to change(PlageOuverture, :count)
        end

        it "returns a success response (i.e. to display the 'new' template)" do
          post :create, params: { organisation_id: organisation.id, plage_ouverture: invalid_attributes }
          expect(response).to be_successful
        end
      end
    end

    describe "PUT #update" do
      subject { put :update, params: { organisation_id: organisation.id, id: plage_ouverture.to_param, plage_ouverture: new_attributes } }

      before { subject }

      context "with valid params" do
        let(:new_attributes) do
          {
            title: "Le nouveau nom",
          }
        end

        it "updates the requested plage_ouverture" do
          expect(response.status).to eq(200)
          plage_ouverture.reload
          expect(plage_ouverture.title).to eq("Le nouveau nom")
        end
      end

      context "with invalid params" do
        let(:new_attributes) do
          {
            start_time: "09:00",
            end_time: "07:00",
          }
        end

        it "returns a success response (i.e. to display the 'edit' template)" do
          expect(response).to be_successful
        end

        it "does not change plage_ouverture start_time and end_time" do
          plage_ouverture.reload
          expect(plage_ouverture.start_time.to_s).not_to eq("09:00:00")
          expect(plage_ouverture.end_time.to_s).not_to eq("07:00:00")
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested plage_ouverture" do
        expect do
          delete :destroy, params: { organisation_id: organisation.id, id: plage_ouverture.to_param }
        end.to change(PlageOuverture, :count).by(-1)
      end

      it "redirects to the plage_ouvertures list" do
        delete :destroy, params: { organisation_id: organisation.id, id: plage_ouverture.to_param }
        expect(response).to redirect_to(organisation_agent_plage_ouvertures_path(organisation, plage_ouverture.agent_id))
      end
    end
  end

  context "CRUD on his plage ouverture" do
    before { sign_in agent }

    it_behaves_like "agent can CRUD plage ouverture"
  end

  context "admin CRUD on an agent's plage ouverture" do
    let(:admin) { create(:agent, role: "admin", organisations: [organisation]) }

    before { sign_in admin }

    it_behaves_like "agent can CRUD plage ouverture"
  end
end
