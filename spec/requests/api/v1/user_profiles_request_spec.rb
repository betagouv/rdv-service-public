# frozen_string_literal: true

describe "api/v1/user_profiles requests", type: :request do
  let!(:organisation) { create(:organisation) }
  let!(:user) { create(:user) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  describe "POST api/v1/user_profiles" do
    context "valid & minimal params" do
      it "works" do
        count_before = UserProfile.count
        post(
          api_v1_user_profiles_path,
          params: {
            organisation_id: organisation.id,
            user_id: user.id
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(200)
        expect(UserProfile.count).to eq(count_before + 1)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["user_profile"]).to be_present
        expect(response_parsed["user_profile"]["user"]["id"]).to eq(user.id)
        expect(response_parsed["user_profile"]["organisation"]["id"]).to eq(organisation.id)
        expect(user.reload.organisations).to include(organisation)
      end
    end

    context "valid & complete params" do
      it "works" do
        count_before = UserProfile.count
        post(
          api_v1_user_profiles_path,
          params: {
            organisation_id: organisation.id,
            user_id: user.id,
            logement: "heberge",
            notes: "Très pressé, vite vite"
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(200)
        expect(UserProfile.count).to eq(count_before + 1)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["user_profile"]).to be_present
        expect(response_parsed["user_profile"]["user"]["id"]).to eq(user.id)
        expect(response_parsed["user_profile"]["organisation"]["id"]).to eq(organisation.id)
        expect(response_parsed["user_profile"]["logement"]).to eq("heberge")
        expect(response_parsed["user_profile"]["notes"]).to eq("Très pressé, vite vite")
        expect(user.reload.organisations).to include(organisation)
      end
    end

    context "invalid params: missing orga id" do
      it "works" do
        count_before = UserProfile.count
        post(
          api_v1_user_profiles_path,
          params: { user_id: user.id },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(403)
        expect(UserProfile.count).to eq(count_before)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["errors"]).to be_present
      end
    end

    context "invalid params: missing user id" do
      it "works" do
        count_before = UserProfile.count
        post(
          api_v1_user_profiles_path,
          params: { organisation_id: organisation.id },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(422)
        expect(UserProfile.count).to eq(count_before)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["errors"]).to be_present
      end
    end

    context "invalid params: unauthorized orga" do
      let!(:unauthorized_orga) { create(:organisation) }

      it "works" do
        count_before = UserProfile.count
        post(
          api_v1_user_profiles_path,
          params: {
            user_id: user.id,
            organisation_id: unauthorized_orga.id
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(403)
        expect(UserProfile.count).to eq(count_before)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["errors"]).to be_present
      end
    end

    context "invalid params: profile already exists" do
      let!(:existing_profile) { create(:user_profile, user: user, organisation: organisation) }

      it "works" do
        count_before = UserProfile.count
        post(
          api_v1_user_profiles_path,
          params: {
            user_id: user.id,
            organisation_id: organisation.id
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(422)
        expect(UserProfile.count).to eq(count_before)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["errors"]).to be_present
      end
    end
  end
end
