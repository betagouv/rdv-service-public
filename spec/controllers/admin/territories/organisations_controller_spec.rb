RSpec.describe Admin::Territories::OrganisationsController, type: :controller do
  let!(:territory) { create(:territory) }
  let!(:organisation) { create(:organisation, territory: territory) }

  before { sign_in agent }

  describe "#new" do
    subject { get :new, params: { territory_id: territory.id } }

    context "agent does not have role in territory" do
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

      it { is_expected.not_to be_successful }
    end
  end

  describe "#create" do
    context "agent has role in territory BUT tries to create orga in other territory" do
      subject { post :create, params: { territory_id: territory2.id, organisation: organisation_params } }

      let!(:agent) do
        create(
          :agent,
          admin_role_in_organisations: [organisation],
          admin_in_territories: [territory]
        )
      end
      let!(:territory2) { create(:territory) }
      let(:organisation_params) { { name: "MDS Test" } }

      it "does not create company" do
        expect { subject }.not_to(change(Organisation, :count))
      end
    end

    context "valid params BUT agent does not have role in territory" do
      subject { post :create, params: { territory_id: territory.id, organisation: organisation_params } }

      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
      let(:organisation_params) { { name: "MDS Test" } }

      it { is_expected.not_to be_successful }

      it "does not create the organisation" do
        expect { subject }.not_to(change(Organisation, :count))
      end
    end
  end
end
