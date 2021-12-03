ries::AgentsController, type: :controller do
  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory) }

  describe "#index" do
    it "assigns territory's agents" do
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory])
      other_agent = create(:agent, basic_role_in_organisations: [organisation])
      sign_in agent

      get :index, params: { territory_id: territory.id }
      expect(assigns(:agents)).to eq([agent, other_agent])
    end
  end
end
