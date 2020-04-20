describe Agents::Creneaux::AgentSearchesController, type: :controller do
  context "with a secretaire signed_in" do
    let!(:agent) { create(:agent, :secretaire) }
    before(:each) { sign_in agent }

    describe "GET index html format" do
      let!(:organisation_id) { agent.organisation_ids.first }
      let(:user) { create(:user) }

      it "should return success" do
        get :index, params: { organisation_id: organisation_id, user_id: user.id }
        expect(response).to have_http_status(:success)
      end

      it "should return success" do
        get :index, params: { organisation_id: organisation_id, user_id: user.id }
        expect(assigns(:user)).to eq(user)
      end

      it "should render template index" do
        get :index, params: { organisation_id: organisation_id, user_id: user.id }
        expect(response).to render_template("index")
      end
    end
  end
end
