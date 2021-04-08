describe Admin::Creneaux::AgentSearchesController, type: :controller do
  context "with a secretaire signed_in" do
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }

    before { sign_in agent }

    describe "GET index html format" do
      let!(:organisation_id) { agent.organisation_ids.first }

      it "returns success" do
        get :index, params: { organisation_id: organisation_id }
        expect(response).to have_http_status(:success)
      end

      it "renders template index" do
        get :index, params: { organisation_id: organisation_id }
        expect(response).to render_template("index")
      end

      it "assignses form with user_ids" do
        user = create(:user)
        get :index, params: { organisation_id: organisation_id, user_ids: [user.id] }
        expect(assigns(:form).user_ids).to eq([user.id.to_s])
      end
    end
  end
end
