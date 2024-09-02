RSpec.describe Admin::CreneauxSearchController do
  context "with a secretaire signed_in" do
    let(:organisation) { create(:organisation) }
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
end
