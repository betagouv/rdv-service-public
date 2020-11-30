describe Admin::RdvByLieuxController, type: :controller do
  describe "#index" do
    let(:organisation) { create(:organisation) }

    context "with a logged agent" do
      let(:agent) { create(:agent, organisations: [organisation]) }

      before(:each) do
        sign_in agent
      end

      it "respond success" do
        get :index, params: { organisation_id: organisation.id }
        expect(response).to be_successful
      end

      it "assigns lieux where current agent have RDV for today" do
        lieu = create(:lieu, organisation: organisation)
        create(:rdv, starts_at: Time.zone.now, agents: [agent], lieu: lieu, organisation: organisation)

        get :index, params: { organisation_id: organisation.id }
        expected = { lieu.name => 1 }
        expect(assigns(:rdvs_per_lieu)).to eq(expected)
      end

      it "assigns all lieux of current agent, even without rdv" do
        lieu = create(:lieu, organisation: organisation)
        autre_lieu = create(:lieu, organisation: organisation)
        create(:rdv, starts_at: Time.zone.now, agents: [agent], lieu: lieu, organisation: organisation)

        get :index, params: { organisation_id: organisation.id }
        expected = { lieu.name => 1, autre_lieu.name => 0 }
        expect(assigns(:rdvs_per_lieu)).to eq(expected)
      end
    end
  end
end
