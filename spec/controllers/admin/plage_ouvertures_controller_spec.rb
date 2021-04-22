describe Admin::PlageOuverturesController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service) }
  let!(:motif) { create(:motif, organisation: organisation, service: service) }
  let!(:lieu1) { create(:lieu, organisation: organisation, name: "MDS Sud", address: "10 rue Belsunce") }

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
        expect(response.body).to include("Permanence")
      end
    end

    describe "GET #index" do
      it "returns a success responses with plage_ouvertures assigned" do
        now = Time.zone.parse("2020-11-23 13h30")
        travel_to(now)
        create(:plage_ouverture, organisation: organisation, agent: agent, first_day: now + 3.days)

        get :index, params: { organisation_id: organisation.id, agent_id: agent.id }
        expect(response).to be_successful
        # TODO : includes plage ouverture
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
        it "creates it and redirects to the index" do
          post(
            :create,
            params: {
              organisation_id: organisation.id,
              plage_ouverture: {
                title: "Permanence ecole",
                motif_ids: [motif.id],
                lieu_id: lieu1.id,
                organisation_id: organisation.id,
                agent_id: agent.id,
                first_day: "17/11/2020",
                start_time: "09:00",
                end_time: "12:00"
              }
            }
          )
          expect(response).to redirect_to(admin_organisation_plage_ouverture_path(organisation, PlageOuverture.last))
          expect(agent.plage_ouvertures.count).to eq 2
        end

        it "send notification after create" do
          expect(Agents::PlageOuvertureMailer).to receive(:plage_ouverture_created).and_return(double(deliver_later: nil))
          post(
            :create,
            params: {
              organisation_id: organisation.id,
              plage_ouverture: {
                title: "Permanence ecole",
                motif_ids: [motif.id],
                lieu_id: lieu1.id,
                organisation_id: organisation.id,
                agent_id: agent.id,
                first_day: "17/11/2020",
                start_time: "09:00",
                end_time: "12:00"
              }
            }
          )
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
                agent_id: agent.id
                # missing fields
              }
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

        it "send notification after create" do
          expect(Agents::PlageOuvertureMailer).to receive(:plage_ouverture_updated).and_return(double(deliver_later: nil))
          put :update, params: { organisation_id: organisation.id, id: plage_ouverture.to_param, plage_ouverture: { title: "Le nouveau nom" } }
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
        delete :destroy, params: { organisation_id: organisation.id, id: plage_ouverture.id }
        expect(agent.plage_ouvertures.count).to eq(0)
        expect(response).to redirect_to(admin_organisation_agent_plage_ouvertures_path(organisation, plage_ouverture.agent_id))
      end

      it "send notification after destroy" do
        expect(Agents::PlageOuvertureMailer).to receive(:plage_ouverture_destroyed).and_return(double(deliver_later: nil))
        delete :destroy, params: { organisation_id: organisation.id, id: plage_ouverture.id }
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
