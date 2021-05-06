RSpec.describe Admin::AbsencesController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  shared_examples "agent can CRUD absences" do
    describe "GET #index" do
      let!(:absence_un_jour_de_juillet) do
        create(:absence, agent: agent,
                         first_day: Date.new(2019, 7, 21),
                         start_time: Tod::TimeOfDay.new(8),
                         end_time: Tod::TimeOfDay.new(10),
                         organisation: organisation)
      end

      let!(:absence_une_semaine_en_aout) do
        create(:absence, agent: agent,
                         first_day: Date.new(2019, 8, 20),
                         start_time: Tod::TimeOfDay.new(8),
                         end_day: Date.new(2019, 8, 31),
                         end_time: Tod::TimeOfDay.new(22),
                         organisation: organisation)
      end

      before do
        travel_to(Time.zone.parse("2019-06-18 18:00"))
        sign_in agent
        get :index, params: { organisation_id: organisation.id, agent_id: agent.id }
      end

      after { travel_back }

      it { expect(response).to be_successful }

      it {
        expect(assigns(:absences).sort).to eq([
          absence_un_jour_de_juillet,
          absence_une_semaine_en_aout
        ].sort)
      }
    end

    describe "GET #new" do
      it "returns a success response" do
        get :new, params: { organisation_id: organisation.id, agent_id: agent.id }
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns a success response" do
        absence = create(:absence, agent_id: agent.id, organisation: organisation)
        get :edit, params: { organisation_id: organisation.id, agent_id: agent.id, id: absence.to_param }
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      context "with valid params" do
        let(:valid_attributes) do
          build(:absence, agent: agent, organisation: organisation).attributes
        end

        it "creates a new Absence" do
          expect do
            post :create, params: { organisation_id: organisation.id, absence: valid_attributes }
          end.to change(Absence, :count).by(1)
        end

        it "redirects to the created absence" do
          post :create, params: { organisation_id: organisation.id, absence: valid_attributes }
          expect(response).to redirect_to(admin_organisation_agent_absences_path(organisation, agent.id))
        end

        it "send notification after create" do
          expect(Agents::AbsenceMailer).to receive(:absence_created).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
          post :create, params: { organisation_id: organisation.id, absence: valid_attributes }
        end
      end

      context "with invalid params" do
        let(:invalid_attributes) do
          {
            agent_id: agent.id,
            first_day: "12/09/2019",
            start_time: "09:00",
            end_time: "07:00"
          }
        end

        it "does not create a new Absence" do
          expect do
            post :create, params: { organisation_id: organisation.id, absence: invalid_attributes }
          end.not_to change(Absence, :count)
        end

        it "returns a success response (i.e. to display the 'new' template)" do
          post :create, params: { organisation_id: organisation.id, absence: invalid_attributes }
          expect(response).to be_successful
        end
      end
    end

    describe "PUT #update" do
      let(:absence) { create(:absence, agent_id: agent.id, organisation: organisation) }

      context "with valid params" do
        let(:new_attributes) do
          {
            title: "Le nouveau nom"
          }
        end

        it "updates the requested absence" do
          put :update, params: { organisation_id: organisation.id, id: absence.to_param, absence: new_attributes }
          absence.reload
          expect(absence.title).to eq("Le nouveau nom")
        end

        it "redirects to the absence" do
          put :update, params: { organisation_id: organisation.id, id: absence.to_param, absence: new_attributes }
          expect(response).to redirect_to(admin_organisation_agent_absences_path(organisation, absence.agent_id))
        end

        it "send notification after update" do
          expect(Agents::AbsenceMailer).to receive(:absence_updated).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
          put :update, params: { organisation_id: organisation.id, id: absence.to_param, absence: new_attributes }
        end
      end

      context "with invalid params" do
        let(:new_attributes) do
          {
            start_time: "09:00",
            end_time: "07:00"
          }
        end

        it "returns a success response (i.e. to display the 'edit' template)" do
          put :update, params: { organisation_id: organisation.id, id: absence.to_param, absence: new_attributes }
          expect(response).to be_successful
        end

        it "does not change absence name" do
          put :update, params: { organisation_id: organisation.id, id: absence.to_param, absence: new_attributes }
          absence.reload
          expect(absence.starts_at.to_s).not_to eq("2019-09-12 16:00:00 +0200")
          expect(absence.ends_at.to_s).not_to eq("2019-09-12 15:00:00 +0200")
        end
      end
    end

    describe "DELETE #destroy" do
      let!(:absence) { create(:absence, agent_id: agent.id, organisation: organisation) }

      it "destroys the requested absence" do
        expect do
          delete :destroy, params: { organisation_id: organisation.id, id: absence.to_param }
        end.to change(Absence, :count).by(-1)
      end

      it "redirects to the absences list" do
        delete :destroy, params: { organisation_id: organisation.id, id: absence.to_param }
        expect(response).to redirect_to(admin_organisation_agent_absences_path(organisation, absence.agent_id))
      end

      it "send notification after delete" do
        expect(Agents::AbsenceMailer).to receive(:absence_destroyed).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
        delete :destroy, params: { organisation_id: organisation.id, id: absence.to_param }
      end
    end
  end

  context "agent can CRUD on his absences" do
    before { sign_in agent }

    it_behaves_like "agent can CRUD absences"
  end

  context "admin can CRUD on an agent's absences" do
    let!(:admin) { create(:agent, admin_role_in_organisations: [organisation]) }

    before { sign_in admin }

    it_behaves_like "agent can CRUD absences"
  end
end
