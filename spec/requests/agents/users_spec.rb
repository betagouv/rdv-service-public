RSpec.describe "Agents::UsersController" do
  describe "#search" do
    describe "when passing an organisation_id the agent doesn't belong to" do
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:organisation) { create(:organisation) }
      let(:other_organisation) { create(:organisation) }

      it "returns a 403 error and an empty body" do
        sign_in agent
        get search_agents_users_path(organisation_id: other_organisation, exclude_ids: [])
        expect(response.status).to eq 403
        expect(response.body).to be_empty
      end
    end
  end
end
