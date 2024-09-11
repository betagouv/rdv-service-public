RSpec.describe Admin::PlageOuverturesController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let!(:motif) { create(:motif, organisation: organisation, service: service) }
  let!(:lieu1) { create(:lieu, organisation: organisation, name: "MDS Sud", address: "10 rue Belsunce, Paris, 75016") }

  shared_examples "agent can CRUD plage ouverture" do
    describe "GET #show" do
      let!(:plage_ouverture) do
        create(
          :plage_ouverture,
          title: "Permanence",
          first_day: Date.new(2020, 11, 16),
          start_time: Tod::TimeOfDay(9),
          end_time: Tod::TimeOfDay(12),
          motifs: [motif],
          lieu: lieu1,
          organisation: organisation,
          agent: agent
        )
      end

      it "displays the PO" do
        get :show, params: { organisation_id: organisation.id, id: plage_ouverture.id }
        expect(response).to be_successful
        expect(assigns(:plage_ouverture)).to eq(plage_ouverture)
      end
    end

    describe "GET #index" do
      it "returns a success responses" do
        now = Time.zone.parse("2020-11-23 13h30")
        travel_to(now)
        plage_ouverture = create(:plage_ouverture, organisation: organisation, agent: agent, first_day: now + 3.days)

        get :index, params: { organisation_id: organisation.id, agent_id: agent.id }
        expect(response).to be_successful
        expect(assigns(:plage_ouvertures)).to eq([plage_ouverture])
      end

      it "assigns plage_ouverture" do
        now = Time.zone.parse("2020-11-23 13h30")
        travel_to(now)
        plage_ouverture = create(:plage_ouverture, organisation: organisation, agent: agent, first_day: now + 3.days)

        get :index, params: { organisation_id: organisation.id, agent_id: agent.id }
        expect(assigns(:plage_ouvertures)).to eq([plage_ouverture])
      end

      it "dispay tab when any expired plage" do
        now = Time.zone.parse("2020-11-23 13h30")
        travel_to(now)
        create(:plage_ouverture, organisation: organisation, agent: agent, first_day: now + 3.days)
        create(:plage_ouverture, organisation: organisation, agent: agent, first_day: now - 3.days)

        get :index, params: { organisation_id: organisation.id, agent_id: agent.id }
        expect(assigns(:display_tabs)).to be true
      end

      it "assigns plage_ouvertures expired when current_tab expired" do
        now = Time.zone.parse("2020-11-23 13h30")
        travel_to(now)
        create(:plage_ouverture, organisation: organisation, agent: agent, first_day: now + 3.days)
        expired_plage_ouverture = create(:plage_ouverture, organisation: organisation, agent: agent, first_day: now - 3.days)

        get :index, params: { organisation_id: organisation.id, agent_id: agent.id, current_tab: "expired" }
        expect(assigns(:plage_ouvertures)).to eq([expired_plage_ouverture])
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
        plage_ouverture = create(:plage_ouverture, organisation: organisation, agent: agent)
        get :edit, params: { organisation_id: organisation.id, id: plage_ouverture.to_param }
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      let!(:plage_ouverture) do
        create(
          :plage_ouverture,
          :weekly,
          first_day: Date.new(2020, 11, 16),
          start_time: Tod::TimeOfDay(9),
          end_time: Tod::TimeOfDay(12),
          motifs: [motif],
          lieu: lieu1,
          organisation: organisation,
          agent: agent
        )
      end

      context "with valid params for non-overlapping exceptional PO" do
        let(:valid_params) do
          {
            organisation_id: organisation.id,
            plage_ouverture: {
              title: "Permanence ecole",
              motif_ids: [motif.id],
              lieu_id: lieu1.id,
              organisation_id: organisation.id,
              agent_id: agent.id,
              first_day: "17/11/2020",
              start_time: "09:00",
              end_time: "12:00",
            },
          }
        end

        it "creates it and redirects to the index" do
          post(:create, params: valid_params)
          expect(response).to redirect_to(admin_organisation_plage_ouverture_path(organisation, PlageOuverture.last))
          expect(agent.plage_ouvertures.count).to eq 2
        end

        it "send notification after create" do
          perform_enqueued_jobs do
            expect { post(:create, params: valid_params) }.to change { ActionMailer::Base.deliveries.size }.by(1)
          end
          expect(ActionMailer::Base.deliveries.last.subject).to eq("RDV Solidarités - Plage d’ouverture créée - Permanence ecole")
        end

        it "skips notification after create when agent has disabled it" do
          agent.update!(plage_ouverture_notification_level: "none")
          expect { post(:create, params: valid_params) }.not_to change { ActionMailer::Base.deliveries.size }
        end
      end

      context "with invalid params" do
        it "does not create a new plage ouverture" do
          post(
            :create,
            params: {
              organisation_id: organisation.id,
              plage_ouverture: {
                motif_ids: [motif.id],
                lieu_id: lieu1.id,
                organisation_id: organisation.id,
                agent_id: agent.id,
                # missing fields
              },
            }
          )
          expect(response).to be_successful
          expect(response).to render_template(:new)
          expect(agent.plage_ouvertures.count).to eq 1
        end
      end
    end

    describe "PUT #update" do
      let!(:plage_ouverture) do
        create(
          :plage_ouverture,
          first_day: Date.new(2020, 11, 16),
          start_time: Tod::TimeOfDay(9),
          end_time: Tod::TimeOfDay(12),
          motifs: [motif],
          lieu: lieu1,
          organisation: organisation,
          agent: agent
        )
      end

      context "with valid params" do
        it "updates the requested plage_ouverture" do
          put :update, params: { organisation_id: organisation.id, id: plage_ouverture.to_param, plage_ouverture: { title: "Le nouveau nom" } }
          expect(response).to redirect_to(admin_organisation_plage_ouverture_path(organisation, plage_ouverture))
        end

        it "send notification after update" do
          ActionMailer::Base.deliveries.clear
          put :update, params: { organisation_id: organisation.id, id: plage_ouverture.to_param, plage_ouverture: { title: "Le nouveau nom" } }
          perform_enqueued_jobs
          expect(ActionMailer::Base.deliveries.size).to eq(1)
          expect(ActionMailer::Base.deliveries.last.subject).to eq("RDV Solidarités - Plage d’ouverture modifiée - Le nouveau nom")
        end

        it "skips notification after update when agent has disabled it" do
          ActionMailer::Base.deliveries.clear
          agent.update!(plage_ouverture_notification_level: "none")
          put :update, params: { organisation_id: organisation.id, id: plage_ouverture.to_param, plage_ouverture: { title: "Le nouveau nom" } }
          expect(ActionMailer::Base.deliveries.size).to eq(0)
        end
      end

      context "with invalid params (end_time before start_time)" do
        it "returns a success response (i.e. to display the 'edit' template) and does not update" do
          put :update, params: { organisation_id: organisation.id, id: plage_ouverture.to_param, plage_ouverture: { start_time: "10:00", end_time: "07:00" } }
          expect(response).to be_successful
          plage_ouverture.reload
          expect(plage_ouverture.start_time.to_s).not_to eq("10:00:00")
          expect(plage_ouverture.end_time.to_s).not_to eq("07:00:00")
        end
      end
    end

    describe "DELETE #destroy" do
      let!(:plage_ouverture) do
        create(
          :plage_ouverture,
          first_day: Date.new(2020, 11, 16),
          start_time: Tod::TimeOfDay(9),
          end_time: Tod::TimeOfDay(12),
          motifs: [motif],
          lieu: lieu1,
          organisation: organisation,
          agent: agent
        )
      end

      it "destroys the requested plage_ouverture" do
        expect do
          delete :destroy, params: { organisation_id: organisation.id, id: plage_ouverture.id }
        end.to change(PlageOuverture, :count).from(1).to(0)
      end

      it "redirect to plages ouverture index" do
        delete :destroy, params: { organisation_id: organisation.id, id: plage_ouverture.id }
        expect(response).to redirect_to(admin_organisation_agent_plage_ouvertures_path(organisation, plage_ouverture.agent_id))
      end

      it "send notification after destroy" do
        ActionMailer::Base.deliveries.clear
        delete :destroy, params: { organisation_id: organisation.id, id: plage_ouverture.id }
        expect(ActionMailer::Base.deliveries.size).to eq(1)
        expect(ActionMailer::Base.deliveries.last.subject).to include("RDV Solidarités - Plage d’ouverture supprimée")
      end

      it "skips notification after destroy when agent has disabled it" do
        agent.update!(plage_ouverture_notification_level: "none")
        ActionMailer::Base.deliveries.clear
        delete :destroy, params: { organisation_id: organisation.id, id: plage_ouverture.id }
        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end

      it "remove plage ouverture without delay" do
        # Difficile de tester le delai qui avait été
        # introduit ici, c'est pourtant la source d'un problème.
        # En attendant de pouvoir tester dans une spec de feature
        # je pose ce test comme justification de la suppresion de
        # l'utilisation du `delay`
        expect do
          delete :destroy, params: { organisation_id: organisation.id, id: plage_ouverture.id }
        end.not_to have_enqueued_job
      end
    end
  end

  context "CRUD on his plage ouverture" do
    before { sign_in agent }

    it_behaves_like "agent can CRUD plage ouverture"
  end

  context "admin CRUD on an agent's plage ouverture" do
    let(:admin) { create(:agent, admin_role_in_organisations: [organisation]) }

    before { sign_in admin }

    it_behaves_like "agent can CRUD plage ouverture"
  end
end
