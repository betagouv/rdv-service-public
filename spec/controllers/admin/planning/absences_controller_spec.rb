RSpec.describe Admin::Planning::AbsencesController, type: :controller do
  render_views

  let!(:organisation) { organisations(:default_org) }

  shared_examples "agent can CRUD absences" do
    describe "GET #index" do
      let(:today) { Time.zone.parse("2019-06-18 18:00") }

      before do
        travel_to(today)
      end

      it "respond successful" do
        get :index, params: { organisation_id: organisation.id, agent_id: agent.id }
        expect(response).to be_successful
      end

      it "assigns absences" do
        absence_juin = create(:absence,
                              agent: agent,
                              first_day: today + 2.days)

        absence_juillet = create(:absence,
                                 agent: agent,
                                 first_day: today + 1.month,
                                 end_day: today + 1.month + 3.days)

        get :index, params: { organisation_id: organisation.id, agent_id: agent.id }
        expect(assigns(:absences)).to contain_exactly(absence_juin, absence_juillet)
      end
    end

    describe "GET #new" do
      it "displays a form to create an absence for the current agent" do
        get :new, params: { organisation_id: organisation.id }
        expect(response.body).to include(%(value="#{agent.id}" name="absence[agent_id]"))
      end

      context "when duplicating an absence from an agent I can manage" do
        it "copies the absence's name" do
          colleague = create(:agent, basic_role_in_organisations: [organisation])
          absence_of_colleague = create(:absence, agent: colleague)
          get :new, params: { organisation_id: organisation.id, agent_id: colleague.id, duplicate_absence_id: absence_of_colleague.id }
          expect(response.body).to include(absence_of_colleague.title)
          expect(response.body).to include(%(value="#{colleague.id}" name="absence[agent_id]"))
        end
      end

      context "when duplicating an absence from an arbitrary agent" do
        it "shows error message and redirects" do
          arbitrary_absence = create(:absence)
          get :new, params: { organisation_id: organisation.id, duplicate_absence_id: arbitrary_absence.id }
          expect(response.body).not_to include(arbitrary_absence.title)
          expect(response).to redirect_to("/")
        end
      end
    end

    describe "GET #edit" do
      it "returns a success response" do
        absence = create(:absence, agent_id: agent.id)
        get :edit, params: { organisation_id: organisation.id, agent_id: agent.id, id: absence.to_param }
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      context "with valid params" do
        let(:valid_attributes) do
          build(:absence, agent: agent).attributes
        end

        it "creates a new Absence" do
          expect do
            post :create, params: { organisation_id: organisation.id, absence: valid_attributes }
          end.to change(Absence, :count).by(1)
        end

        it "redirects to the created absence" do
          post :create, params: { organisation_id: organisation.id, absence: valid_attributes }
          expect(response).to redirect_to(admin_organisation_planning_absences_path(organisation, agent_id: agent.id))
        end

        it "send notification after create" do
          perform_enqueued_jobs do
            expect do
              post :create, params: { organisation_id: organisation.id, absence: valid_attributes }
            end.to change { ActionMailer::Base.deliveries.size }.by(1)
          end

          expect(ActionMailer::Base.deliveries.last.subject).to include("RDV Service Public - Indisponibilité créée")
        end

        it "skips notification after create when agent has disabled it" do
          agent.update_columns(absence_notification_level: "none") # rubocop:disable Rails/SkipsModelValidations

          expect do
            post :create, params: { organisation_id: organisation.id, absence: valid_attributes }
          end.not_to change { ActionMailer::Base.deliveries.size }
        end
      end

      context "with invalid params" do
        let(:invalid_attributes) do
          {
            agent_id: agent.id,
            first_day: "12/09/2019",
            start_time: "09:00",
            # end_time before start_time !
            end_time: "07:00",
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
      let(:absence) { create(:absence, agent_id: agent.id) }

      context "with valid params" do
        let(:new_attributes) do
          {
            title: "Le nouveau nom",
          }
        end

        it "updates the requested absence" do
          put :update, params: { organisation_id: organisation.id, id: absence.to_param, absence: new_attributes }
          absence.reload
          expect(absence.title).to eq("Le nouveau nom")
        end

        it "redirects to the absence" do
          put :update, params: { organisation_id: organisation.id, id: absence.to_param, absence: new_attributes }
          expect(response).to redirect_to(admin_organisation_planning_absences_path(organisation, agent_id: absence.agent_id))
        end

        it "send notification after update" do
          perform_enqueued_jobs do
            expect do
              put :update, params: { organisation_id: organisation.id, id: absence.to_param, absence: new_attributes }
            end.to change { ActionMailer::Base.deliveries.size }.by(1)
          end
          expect(ActionMailer::Base.deliveries.last.subject).to include("RDV Service Public - Indisponibilité modifiée - Le nouveau nom")
        end

        it "skips notification after update when agent has disabled it" do
          agent.update_columns(absence_notification_level: "none") # rubocop:disable Rails/SkipsModelValidations

          expect do
            put :update, params: { organisation_id: organisation.id, id: absence.to_param, absence: new_attributes }
          end.not_to change { ActionMailer::Base.deliveries.size }
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
      let!(:absence) { create(:absence, :once_a_week, agent_id: agent.id) }

      it "destroys the requested absence" do
        expect do
          delete :destroy, params: { organisation_id: organisation.id, id: absence.to_param }
        end.to change(Absence, :count).by(-1)
      end

      it "redirects to the absences list" do
        delete :destroy, params: { organisation_id: organisation.id, id: absence.to_param }
        expect(response).to redirect_to(admin_organisation_planning_absences_path(organisation, agent_id: absence.agent_id))
      end

      it "enqueues notification after delete" do
        delete :destroy, params: { organisation_id: organisation.id, id: absence.to_param }
        expect { perform_enqueued_jobs }.to change { ActionMailer::Base.deliveries.size }.by(1)
        expect(ActionMailer::Base.deliveries.last.subject).to include("RDV Service Public - Indisponibilité supprimée")
      end

      it "skips notification after delete when agent has disabled it" do
        agent.update_columns(absence_notification_level: "none") # rubocop:disable Rails/SkipsModelValidations

        expect do
          delete :destroy, params: { organisation_id: organisation.id, id: absence.to_param }
        end.not_to change { ActionMailer::Base.deliveries.size }
      end
    end
  end

  context "agent can CRUD on his absences" do
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

    before { sign_in agent }

    it_behaves_like "agent can CRUD absences"
  end

  context "admin can CRUD on an agent's absences" do
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

    before { sign_in agent }

    it_behaves_like "agent can CRUD absences"
  end
end
