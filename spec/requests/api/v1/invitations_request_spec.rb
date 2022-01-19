# frozen_string_literal: true

describe "api/v1/agents requests", type: :request do
  describe "GET api/v1/invitations/:invitation_token" do
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation], email: "jean@jacques.fr") }

    context "when the token exists" do
      let!(:invitation_token) do
        user.invite! { |u| u.skip_invitation = true }
        user.raw_invitation_token
      end

      it "returns the user" do
        get api_v1_invitation_path(invitation_token), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(200)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["user"]["id"]).to eq(user.id)
      end

      context "when not authorized" do
        let!(:other_organisation) { create(:organisation) }
        let!(:agent) { create(:agent, basic_role_in_organisations: [other_organisation]) }

        it "returns 403" do
          get api_v1_invitation_path(invitation_token), headers: api_auth_headers_for_agent(agent)
          expect(response.status).to eq(403)
          response_parsed = JSON.parse(response.body)
          expect(response_parsed["errors"]).to be_present
        end
      end
    end

    context "when the token does not exist" do
      it "returns 404" do
        get api_v1_invitation_path("some-random-token"), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(404)
      end
    end
  end
end
