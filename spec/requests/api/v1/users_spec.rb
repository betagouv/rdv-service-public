RSpec.describe "/api/v1/users" do
  let(:my_organisation) { create(:organisation) }
  let(:myself) { create(:agent, basic_role_in_organisations: [my_organisation]) }

  let(:headers) { api_auth_headers_for_agent(myself) }

  describe "POST #create" do
    context "simple case, create a user in my org" do
      let(:params) do
        {
          first_name: "Francis",
          last_name: "Factice",
          organisation_ids: [my_organisation.id],
        }
      end

      it "creates the user" do
        expect do
          post "/api/v1/users", headers:, params:, as: :json
        end.to change(User, :count).by(1)
        expect(User.last).to have_attributes(
          first_name: "Francis",
          last_name: "Factice",
          organisations: [my_organisation]
        )
      end
    end

    context "when passing arbitrary referent_agent_ids" do
      let(:agent_from_my_org) { create(:agent, basic_role_in_organisations: [my_organisation]) }
      let(:agent_from_other_org) { create(:agent) }

      let(:params) do
        {
          first_name: "Francis",
          last_name: "Factice",
          organisation_ids: [my_organisation.id],
          referent_agent_ids: [agent_from_other_org.id, myself.id],
        }
      end

      it "agent ids outside my orgs are ignored" do
        post "/api/v1/users", headers:, params:, as: :json
        expect(User.last.referent_agents).to eq([myself])
      end
    end
  end

  describe "PUT #update" do
    let(:existing_user) { create(:user, organisations: [my_organisation]) }

    context "simple case, update last name" do
      let(:params) do
        {
          last_name: "Fastoche"
        }
      end

      it "updates successfully" do
        expect do
          put "/api/v1/users/#{existing_user.id}", headers:, params:, as: :json
        end.to change { existing_user.reload.last_name }
        expect(existing_user.reload.last_name).to eq("Fastoche")
      end
    end

    context "when passing arbitrary referent_agent_ids" do
      let(:agent_from_other_org) { create(:agent) }

      let(:params) do
        {
          referent_agent_ids: [agent_from_other_org.id, myself.id]
        }
      end

      it "filters out external agents" do
        expect(existing_user.reload.referent_agents).to be_empty
        put "/api/v1/users/#{existing_user.id}", headers:, params:, as: :json
        expect(existing_user.reload.referent_agents).to eq([myself])
      end
    end
  end
end
