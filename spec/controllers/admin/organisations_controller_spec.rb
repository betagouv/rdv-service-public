describe Admin::OrganisationsController, type: :controller do
  let(:organisation) { create(:organisation) }

  before { sign_in agent }

  describe "#new" do
    subject { get :new }

    context "agent is admin" do
      let!(:agent) { create(:agent, :admin, organisations: [organisation]) }
      it { should be_successful }
    end

    context "agent is regular agent, not admin" do
      let!(:agent) { create(:agent, organisations: [organisation]) }
      it { should_not be_successful }
    end
  end

  describe "#create" do
    subject { post :create, params: { organisation: organisation_params } }

    context "admin agent, valid params" do
      let!(:agent) { create(:agent, :admin, organisations: [organisation]) }
      let(:organisation_params) { { name: "MDS Test", departement: "33" } }

      it "should create company" do
        expect { subject }.to change { Organisation.count }.by(1)
      end
    end

    context "admin agent, invalid params" do
      let!(:agent) { create(:agent, :admin, organisations: [organisation]) }
      let(:organisation_params) { { name: "MDS Test", departement: "3333" } }

      it { should render_template("admin/organisations/new") }
      it "should not create company" do
        expect { subject }.not_to(change { Organisation.count })
      end
    end

    context "regular agent, valid params" do
      let!(:agent) { create(:agent, organisations: [organisation]) }
      let(:organisation_params) { { name: "MDS Test", departement: "33" } }
      it { should_not be_successful }
      it "should not create company" do
        expect { subject }.not_to(change { Organisation.count })
      end
    end
  end

  context "with a admin agent signed in" do
    let!(:agent) { create(:agent, :admin, organisations: [organisation]) }

    describe "#update" do
      it "should redirect to organisation show" do
        put :update, params: { id: organisation.id, organisation: { name: "a new name" } }
        expect(response).to redirect_to(admin_organisation_path(organisation))
      end

      { phone_number: "01 23 45 56 78", website: "http://www.pasdecalais.fr", email: "vaneecke.elodie@pasdecalais.fr" }.each do |attribute, value|
        it "should update #{attribute}" do
          params = {}
          params[attribute] = value
          put :update, params: { id: organisation.id, organisation: params }
          expect(organisation.reload.send(attribute)).to eq(value)
        end
      end
    end
  end
end
