RSpec.describe Admin::CreneauxSearchController do
  let(:organisation) { create(:organisation) }

  context "with a secretaire signed_in" do
    let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }

    before { sign_in agent }

    it "returns success and renders the index" do
      get :index, params: { organisation_id: organisation.id }
      expect(response).to have_http_status(:success)
      expect(response).to render_template("index")
    end

    it "assignses form with user_ids" do
      user = create(:user)
      get :index, params: { organisation_id: organisation.id, user_ids: [user.id] }
      expect(assigns(:form).user_ids).to eq([user.id.to_s])
    end

    it "assigns enabled lieux" do
      enabled_lieu = create(:lieu, enabled: true, organisation: organisation)
      create(:lieu, enabled: false, organisation: organisation)
      get :index, params: { organisation_id: organisation.id }
      expect(assigns(:lieux)).to eq([enabled_lieu])
    end

    it "assigns available agents" do
      other_agent = create(:agent, basic_role_in_organisations: [organisation])
      get :index, params: { organisation_id: organisation.id }
      expect(assigns(:agents)).to contain_exactly(other_agent, agent)
    end

    it "assigns available teams" do
      team = create(:team, territory: organisation.territory)
      get :index, params: { organisation_id: organisation.id }
      expect(assigns(:teams)).to eq([team])
    end
  end

  describe "#selection_creneaux" do
    it "assigns search_result" do
      now = Time.zone.parse("2021-11-17 11h40")
      travel_to(now)
      agent = create(:agent, :secretaire, basic_role_in_organisations: [organisation])
      motif = create(:motif, organisation: organisation)
      from_date = Date.new(2021, 11, 23)
      agent_ids = []
      lieu = create(:lieu, organisation: organisation)

      create(:plage_ouverture, first_day: from_date, start_time: Tod::TimeOfDay(9), end_time: Tod::TimeOfDay(11), organisation: organisation, motifs: [motif], agent: agent, lieu: lieu)

      sign_in agent

      get :selection_creneaux, params: {
        organisation_id: organisation.id,
        service_id: agent.services.first.id,
        motif_id: motif.id,
        from_date: from_date,
        agent_ids: agent_ids,
        lieu_id: lieu,
      }

      expect(assigns(:search_result)).not_to be_nil
    end

    describe "edge cases" do
      render_views

      context "when there is no search results" do
        it "doesn't crash" do
          agent = create(:agent, :secretaire, basic_role_in_organisations: [organisation])
          motif = create(:motif, organisation: organisation)

          sign_in agent

          expect do
            get :selection_creneaux, params: {
              organisation_id: organisation.id,
              motif_id: motif.id,
            }
          end.not_to raise_error
          expect(unescaped_response_body).to include("Aucun créneau disponible dans l'organisation #{organisation.name} pour les filtres sélectionnés.")
        end
      end
    end
  end
end
