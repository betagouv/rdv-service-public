describe Admin::OrganisationsController, type: :controller do
  let!(:territory) { create(:territory) }
  let!(:organisation) { create(:organisation, territory: territory) }

  before { sign_in agent }

  describe "#new" do
    subject { get :new, params: { territory_id: territory.id } }

    context "agent has role in territory" do
      let!(:agent) do
        create(
          :agent,
          admin_role_in_organisations: [organisation],
          role_in_territories: [territory]
        )
      end
      it { should be_successful }
    end

    context "agent does not have role in territory" do
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
      it { should_not be_successful }
    end
  end

  describe "#create" do
    subject { post :create, params: { organisation: organisation_params } }

    context "agent has role in territory, valid params" do
      let!(:agent) do
        create(
          :agent,
          admin_role_in_organisations: [organisation],
          role_in_territories: [territory]
        )
      end
      let(:organisation_params) { { name: "MDS Test", territory_id: territory.id } }

      it "should create company" do
        expect { subject }.to change { Organisation.count }.by(1)
      end
    end

    context "agent has role in territory BUT tries to create orga in other territory" do
      let!(:agent) do
        create(
          :agent,
          admin_role_in_organisations: [organisation],
          role_in_territories: [territory]
        )
      end
      let!(:territory2) { create(:territory) }
      let(:organisation_params) { { name: "MDS Test", territory_id: territory2.id } }

      it { should_not render_template("admin/organisations/new") }
      it "should not create company" do
        expect { subject }.not_to(change { Organisation.count })
      end
    end

    context "valid params BUT agent does not have role in territory" do
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
      let(:organisation_params) { { name: "MDS Test", departement: "33" } }
      it { should_not be_successful }
      it "should not create company" do
        expect { subject }.not_to(change { Organisation.count })
      end
    end
  end

  describe "#update" do
    context "orga admin" do
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

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
