# frozen_string_literal: true

describe "api/v1/users requests", type: :request do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  describe "GET api/v1/users/:id" do
    context "authorized user ID" do
      let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation]) }

      it "works" do
        get api_v1_user_path(user), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(200)
        expect(parsed_response_body["user"]).to be_present
        expect(parsed_response_body["user"]["id"]).to eq(user.id)
        expect(parsed_response_body["user"]["first_name"]).to eq("Jean")
        expect(parsed_response_body["user"]["last_name"]).to eq("JACQUES")
        expect(parsed_response_body["user"]["user_profiles"]).to be_present
        expect(parsed_response_body["user"]["user_profiles"].size).to eq 1
        expect(parsed_response_body["user"]["user_profiles"][0]["organisation"]["id"]).to eq(organisation.id)
      end
    end

    context "authorized user ID also belongs to other organisation" do
      let!(:unauthorized_orga) { create(:organisation) }
      let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation, unauthorized_orga]) }

      it "works" do
        get api_v1_user_path(user), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(200)
        expect(parsed_response_body["user"]).to be_present
        expect(parsed_response_body["user"]["id"]).to eq(user.id)
        expect(parsed_response_body["user"]["first_name"]).to eq("Jean")
        expect(parsed_response_body["user"]["last_name"]).to eq("JACQUES")
        expect(parsed_response_body["user"]["user_profiles"]).to be_present
        expect(parsed_response_body["user"]["user_profiles"].size).to eq 1
        expect(parsed_response_body["user"]["user_profiles"][0]["organisation"]["id"]).to eq(organisation.id)
      end
    end

    context "unauthorized user ID" do
      let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [create(:organisation)]) }

      it "works" do
        get api_v1_user_path(user), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(403)
        expect(parsed_response_body["errors"]).to be_present
      end
    end
  end

  describe "POST api/v1/users" do
    context "valid & minimal params" do
      it "works" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: {
            organisation_ids: [organisation.id],
            first_name: "Jean",
            last_name: "Jacques",
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(200)
        expect(User.count).to eq(user_count_before + 1)
        expect(parsed_response_body["user"]).to be_present
        expect(parsed_response_body["user"]["id"]).to be_present
        user = User.find(parsed_response_body["user"]["id"])
        expect(user.organisations).to match_array([organisation])
        expect(user.first_name).to eq("Jean")
        expect(user.last_name).to eq("Jacques")
      end
    end

    context "valid & complete params" do
      it "works" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: {
            organisation_ids: [organisation.id],
            first_name: "Jean",
            last_name: "Jacques",
            birth_name: "Fripouille",
            birth_date: "1976-10-01",
            email: "jean@jacques.fr",
            address: "10 rue du Havre, Paris",
            caisse_affiliation: "caf",
            affiliation_number: "101010",
            family_situation: "single",
            number_of_children: 3,
            notify_by_sms: false,
            notify_by_email: false,
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(200)
        expect(User.count).to eq(user_count_before + 1)
        expect(parsed_response_body["user"]).to be_present
        expect(parsed_response_body["user"]["id"]).to be_present
        user = User.find(parsed_response_body["user"]["id"])
        expect(user.organisations).to match_array([organisation])
        expect(user.first_name).to eq("Jean")
        expect(user.last_name).to eq("Jacques")
        expect(user.birth_name).to eq("Fripouille")
        expect(user.birth_date).to eq(Date.new(1976, 10, 1))
        expect(user.email).to eq("jean@jacques.fr")
        expect(user.address).to eq("10 rue du Havre, Paris")
        expect(user.caisse_affiliation).to eq("caf")
        expect(user.affiliation_number).to eq("101010")
        expect(user.family_situation).to eq("single")
        expect(user.number_of_children).to eq(3)
        expect(user.notify_by_sms).to eq(false)
        expect(user.notify_by_email).to eq(false)
      end
    end

    context "valid & relative" do
      let!(:user_responsible) { create(:user) }

      it "works" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: {
            organisation_ids: [organisation.id],
            first_name: "Jean",
            last_name: "Jacques",
            responsible_id: user_responsible.id,
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(200)
        expect(User.count).to eq(user_count_before + 1)
        expect(parsed_response_body["user"]).to be_present
        expect(parsed_response_body["user"]["id"]).to be_present
        user = User.find(parsed_response_body["user"]["id"])
        expect(user.organisations).to match_array([organisation])
        expect(user.first_name).to eq("Jean")
        expect(user.last_name).to eq("Jacques")
        expect(user.responsible).to eq(user_responsible)
      end
    end

    context "invalid: missing orgas" do
      let!(:other_orga) { create(:organisation) }

      it "does not work" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: { first_name: "Jean", last_name: "Jacques" },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(422)
        expect(User.count).to eq(user_count_before)
        expect(parsed_response_body["errors"]).not_to be_empty
      end
    end

    context "invalid: missing required attribute" do
      let!(:other_orga) { create(:organisation) }

      it "does not work" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: {
            organisation_ids: [organisation.id],
            first_name: "Jean", # missing last_name
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(422)
        expect(User.count).to eq(user_count_before)
        expect(parsed_response_body["errors"]).not_to be_empty
      end
    end

    context "invalid: misformatted attribute" do
      let!(:other_orga) { create(:organisation) }

      it "does not work" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: {
            organisation_ids: [organisation.id],
            first_name: "Jean",
            last_name: "Jacques",
            phone_number: "blah blah",
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(422)
        expect(User.count).to eq(user_count_before)
        expect(parsed_response_body["errors"]).not_to be_empty
      end
    end

    context "invalid: existing email" do
      let!(:other_orga) { create(:organisation) }
      let!(:existing_user) { create(:user, email: "jean@jacques.fr") }

      it "does not work" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: {
            organisation_ids: [organisation.id],
            first_name: "Jean",
            last_name: "Jacques",
            email: "jean@jacques.fr",
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(422)
        expect(User.count).to eq(user_count_before)
        expect(parsed_response_body["errors"]).not_to be_empty
        expect(parsed_response_body["errors"]["email"].first).to \
          eq({ "error" => "taken", "value" => "jean@jacques.fr", "id" => existing_user.id })
      end
    end
  end

  describe "GET api/v1/users" do
    context "multiple organisations" do
      let!(:user) { create(:user, organisations: [organisation]) }
      let!(:organisation2) { create(:organisation) }
      let!(:user2) { create(:user, organisations: [organisation2]) }
      let!(:organisation3) { create(:organisation) }
      let!(:user3) { create(:user, organisations: [organisation3]) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation, organisation2]) }

      it "returns policy scoped users" do
        get api_v1_users_path, headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(200)
        expect(parsed_response_body["users"].pluck("id")).to contain_exactly(user.id, user2.id)
      end
    end

    context "when a list of ids is passed" do
      let!(:user1) { create(:user, organisations: [organisation]) }
      let!(:user2) { create(:user, organisations: [organisation]) }

      it "returns the specified user list" do
        get(
          api_v1_users_path,
          params: { ids: [user1.id] },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(200)
        expect(parsed_response_body["users"].pluck("id")).to contain_exactly(user1.id)
      end
    end
  end

  describe "GET api/v1/organisations/:id/users" do
    context "when the agent does not belong to the organisation" do
      let!(:other_orga) { create(:organisation) }
      let!(:user) { create(:user, organisations: [other_orga]) }

      it "does not return the users list" do
        get api_v1_organisation_users_path(other_orga), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(200)
        expect(parsed_response_body["users"]).to eq([])
      end
    end

    context "when the agent belongs to multiple organisations" do
      let!(:user1) { create(:user, organisations: [organisation]) }
      let!(:organisation2) { create(:organisation) }
      let!(:user2) { create(:user, organisations: [organisation2]) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation, organisation2]) }

      it "returns the organisation users only" do
        get api_v1_organisation_users_path(organisation), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(200)
        expect(parsed_response_body["users"].pluck("id")).to contain_exactly(user1.id)
      end
    end
  end

  describe "GET api/v1/users/:id/invite" do
    context "Existing user with email" do
      let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation], email: "jean@jacques.fr") }

      it "works" do
        get invite_api_v1_user_path(user), headers: api_auth_headers_for_agent(agent), as: :json
        expect(response.status).to eq(200)
        expect(parsed_response_body["invitation_url"]).to be_present
        expect(parsed_response_body["invitation_url"]).to start_with("http://www.example.com/users/invitation/accept?invitation_token=")
        user.reload
        expect(user.invitation_due_at).to eq(user.invitation_created_at + User.invite_for)
        expect(user.invited_through).to eq("external")
      end
    end

    context "Existing user without email" do
      let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", email: nil, organisations: [organisation]) }

      it "works" do
        get invite_api_v1_user_path(user), headers: api_auth_headers_for_agent(agent), as: :json
        expect(response.status).to eq(200)
        expect(parsed_response_body["invitation_token"]).to be_present
        user.reload
        expect(user.invitation_due_at).to eq(user.invitation_created_at + User.invite_for)
      end
    end

    context "unauthorized user ID" do
      let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [create(:organisation)]) }

      it "works" do
        get invite_api_v1_user_path(user), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(403)
        expect(parsed_response_body["errors"]).to be_present
      end
    end
  end

  describe "POST api/v1/users/:id/invite" do
    context "Existing user with email" do
      let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation], email: "jean@jacques.fr") }

      it "works" do
        post invite_api_v1_user_path(user), headers: api_auth_headers_for_agent(agent), as: :json
        expect(response.status).to eq(200)
        expect(parsed_response_body["invitation_url"]).to be_present
        expect(parsed_response_body["invitation_token"]).to be_present
        expect(parsed_response_body["invitation_url"]).to start_with("http://www.example.com/users/invitation/accept?invitation_token=")
        user.reload
        expect(user.invitation_due_at).to eq(user.invitation_created_at + User.invite_for)
        expect(user.invited_through).to eq("external")
      end
    end

    context "Existing user without email" do
      let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", email: nil, organisations: [organisation]) }

      it "works" do
        post invite_api_v1_user_path(user), headers: api_auth_headers_for_agent(agent), as: :json
        expect(response.status).to eq(200)
        expect(parsed_response_body["invitation_token"]).to be_present
        expect(parsed_response_body["invitation_url"]).to be_present
        user.reload
        expect(user.invitation_due_at).to eq(user.invitation_created_at + User.invite_for)
      end
    end

    context "with custom invite_for" do
      let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation], email: "jean@jacques.fr") }

      it "works" do
        post(
          invite_api_v1_user_path(user),
          headers: api_auth_headers_for_agent(agent),
          params: {
            invite_for: 86_400, # invite_for en secondes (86400 = 1 jour),
          },
          as: :json
        )
        expect(response.status).to eq(200)
        expect(parsed_response_body["invitation_url"]).to be_present
        expect(parsed_response_body["invitation_url"]).to start_with("http://www.example.com/users/invitation/accept?invitation_token=")
        user.reload
        expect(user.invitation_due_at).to eq(user.invitation_created_at + 1.day)
      end
    end

    context "unauthorized user ID" do
      let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [create(:organisation)]) }

      it "works" do
        get invite_api_v1_user_path(user), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(403)
        expect(parsed_response_body["errors"]).to be_present
      end
    end
  end

  describe "GET api/v1/:organisation_id/users/:user_id" do
    let!(:user) { create(:user, organisations: [organisation]) }

    context "when the user belongs to the org" do
      it "works" do
        get api_v1_organisation_user_path(organisation, user), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(200)
        expect(parsed_response_body["user"]["id"]).to eq(user.id)
      end
    end

    context "when the user does not belong to the org" do
      let!(:another_org) { create(:organisation) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation, another_org]) }
      let!(:user) { create(:user, organisations: [another_org]) }

      it "is not found" do
        get api_v1_organisation_user_path(organisation, user), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(404)
      end
    end

    context "when the agent does not belong to the org" do
      let!(:another_org) { create(:organisation) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [another_org]) }
      let!(:user) { create(:user, organisations: [organisation]) }

      it "is not authorized" do
        get api_v1_organisation_user_path(organisation, user), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(403)
      end
    end
  end

  describe "PATCH api/v1/users" do
    let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation]) }

    context "valid & minimal params" do
      it "works" do
        patch(
          api_v1_user_path(user),
          params: {
            first_name: "Alain",
            last_name: "Deloin",
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(200)
        user.reload
        expect(user.first_name).to eq("Alain")
        expect(user.last_name).to eq("Deloin")
        expect(parsed_response_body["user"]).to be_present
        expect(parsed_response_body["user"]["id"]).to be_present
      end
    end

    context "valid & complete params" do
      it "works" do
        patch(
          api_v1_user_path(user),
          params: {
            first_name: "Alain",
            last_name: "Deloin",
            birth_name: "Bourdon",
            birth_date: "1976-10-01",
            email: "alain@deloin.fr",
            address: "10 rue du Havre, Paris",
            caisse_affiliation: "caf",
            affiliation_number: "101010",
            family_situation: "single",
            number_of_children: 3,
            notify_by_sms: false,
            notify_by_email: false,
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(200)
        user.reload
        expect(user.first_name).to eq("Alain")
        expect(user.last_name).to eq("Deloin")
        expect(user.birth_name).to eq("Bourdon")
        expect(user.birth_date).to eq(Date.new(1976, 10, 1))
        user.reload
        expect(user.email).to eq("alain@deloin.fr")
        expect(user.address).to eq("10 rue du Havre, Paris")
        expect(user.caisse_affiliation).to eq("caf")
        expect(user.affiliation_number).to eq("101010")
        expect(user.family_situation).to eq("single")
        expect(user.number_of_children).to eq(3)
        expect(user.notify_by_sms).to eq(false)
        expect(user.notify_by_email).to eq(false)
        expect(parsed_response_body["user"]).to be_present
        expect(parsed_response_body["user"]["id"]).to be_present
      end
    end

    context "valid & relative" do
      let!(:user_responsible) { create(:user) }

      it "works" do
        patch(
          api_v1_user_path(user),
          params: {
            first_name: "Alain",
            last_name: "Deloin",
            responsible_id: user_responsible.id,
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(200)
        user.reload
        expect(parsed_response_body["user"]).to be_present
        expect(user.first_name).to eq("Alain")
        expect(user.last_name).to eq("Deloin")
        expect(user.responsible).to eq(user_responsible)
      end
    end

    context "invalid: misformatted attribute" do
      it "does not work" do
        patch(
          api_v1_user_path(user),
          params: {
            first_name: "Jean",
            last_name: "Jacques",
            phone_number: "blah blah",
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(422)
        expect(parsed_response_body["errors"]).not_to be_empty
      end
    end

    context "invalid: existing email" do
      let!(:existing_user) { create(:user, email: "jean@jacques.fr") }

      it "does not work" do
        patch(
          api_v1_user_path(user),
          params: {
            first_name: "Jean",
            last_name: "Jacques",
            email: "jean@jacques.fr",
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(422)
        expect(parsed_response_body["errors"]).not_to be_empty
        expect(parsed_response_body["errors"]["email"].first).to \
          eq({ "error" => "taken", "value" => "jean@jacques.fr", "id" => existing_user.id })
      end
    end
  end
end
