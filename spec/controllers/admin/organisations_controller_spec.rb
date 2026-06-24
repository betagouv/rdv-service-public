RSpec.describe Admin::OrganisationsController, type: :controller do
  let!(:organisation) { create(:organisation) }

  before { sign_in agent }

  describe "#update" do
    context "orga admin" do
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

      it "redirects to organisation show" do
        put :update, params: { id: organisation.id, organisation: { name: "a new name" } }
        expect(response).to redirect_to(admin_organisation_path(organisation))
      end

      { phone_number: "01 23 45 56 78", website: "http://www.pasdecalais.fr", email: "francis@factice.org" }.each do |attribute, value|
        it "updates #{attribute}" do
          params = {}
          params[attribute] = value
          put :update, params: { id: organisation.id, organisation: params }
          expect(organisation.reload.send(attribute)).to eq(value)
        end
      end
    end
  end
end
