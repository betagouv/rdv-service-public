describe "api/v1/users requests", type: :request do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  describe "GET api/v1/users/:id" do
    context "authorized user ID" do
      let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation]) }
      it "should work" do
        get api_v1_user_path(user), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(200)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["user"]).to be_present
        expect(response_parsed["user"]["id"]).to eq(user.id)
        expect(response_parsed["user"]["first_name"]).to eq("Jean")
        expect(response_parsed["user"]["last_name"]).to eq("JACQUES")
        expect(response_parsed["user"]["user_profiles"]).to be_present
        expect(response_parsed["user"]["user_profiles"].size).to eq 1
        expect(response_parsed["user"]["user_profiles"][0]["organisation"]["id"]).to eq(organisation.id)
      end
    end

    context "authorized user ID also belongs to other organisation" do
      let!(:unauthorized_orga) { create(:organisation) }
      let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [organisation, unauthorized_orga]) }
      it "should work" do
        get api_v1_user_path(user), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(200)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["user"]).to be_present
        expect(response_parsed["user"]["id"]).to eq(user.id)
        expect(response_parsed["user"]["first_name"]).to eq("Jean")
        expect(response_parsed["user"]["last_name"]).to eq("JACQUES")
        expect(response_parsed["user"]["user_profiles"]).to be_present
        expect(response_parsed["user"]["user_profiles"].size).to eq 1
        expect(response_parsed["user"]["user_profiles"][0]["organisation"]["id"]).to eq(organisation.id)
      end
    end

    context "unauthorized user ID" do
      let!(:user) { create(:user, first_name: "Jean", last_name: "JACQUES", organisations: [create(:organisation)]) }
      it "should work" do
        get api_v1_user_path(user), headers: api_auth_headers_for_agent(agent)
        expect(response.status).to eq(403)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["errors"]).to be_present
      end
    end
  end

  describe "POST api/v1/users" do
    context "valid & minimal params" do
      it "should work" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: {
            organisation_ids: [organisation.id],
            first_name: "Jean",
            last_name: "Jacques"
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(200)
        expect(User.count).to eq(user_count_before + 1)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["user"]).to be_present
        expect(response_parsed["user"]["id"]).to be_present
        user = User.find(response_parsed["user"]["id"])
        expect(user.organisations).to match_array([organisation])
        expect(user.first_name).to eq("Jean")
        expect(user.last_name).to eq("JACQUES")
      end
    end

    context "valid & complete params" do
      it "should work" do
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
            notify_by_email: false
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(200)
        expect(User.count).to eq(user_count_before + 1)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["user"]).to be_present
        expect(response_parsed["user"]["id"]).to be_present
        user = User.find(response_parsed["user"]["id"])
        expect(user.organisations).to match_array([organisation])
        expect(user.first_name).to eq("Jean")
        expect(user.last_name).to eq("JACQUES")
        expect(user.birth_name).to eq("FRIPOUILLE")
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
      it "should work" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: {
            organisation_ids: [organisation.id],
            first_name: "Jean",
            last_name: "Jacques",
            responsible_id: user_responsible.id
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(200)
        expect(User.count).to eq(user_count_before + 1)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["user"]).to be_present
        expect(response_parsed["user"]["id"]).to be_present
        user = User.find(response_parsed["user"]["id"])
        expect(user.organisations).to match_array([organisation])
        expect(user.first_name).to eq("Jean")
        expect(user.last_name).to eq("JACQUES")
        expect(user.responsible).to eq(user_responsible)
      end
    end

    context "invalid: forbidden orga" do
      let!(:other_orga) { create(:organisation) }
      it "should not work" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: {
            organisation_ids: [other_orga.id],
            first_name: "Jean",
            last_name: "Jacques"
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(403)
        expect(User.count).to eq(user_count_before)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["errors"]).not_to be_empty
      end
    end

    context "invalid: empty orgas" do
      let!(:other_orga) { create(:organisation) }
      it "should not work" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: {
            organisation_ids: [],
            first_name: "Jean",
            last_name: "Jacques"
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(403)
        expect(User.count).to eq(user_count_before)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["errors"]).not_to be_empty
      end
    end

    context "invalid: missing orgas" do
      let!(:other_orga) { create(:organisation) }
      it "should not work" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: { first_name: "Jean", last_name: "Jacques" },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(422)
        expect(User.count).to eq(user_count_before)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["errors"]).not_to be_empty
      end
    end

    context "invalid: missing required attribute" do
      let!(:other_orga) { create(:organisation) }
      it "should not work" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: {
            organisation_ids: [organisation.id],
            first_name: "Jean" # missing last_name
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(422)
        expect(User.count).to eq(user_count_before)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["errors"]).not_to be_empty
      end
    end

    context "invalid: misformatted attribute" do
      let!(:other_orga) { create(:organisation) }
      it "should not work" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: {
            organisation_ids: [organisation.id],
            first_name: "Jean",
            last_name: "Jacques",
            phone_number: "blah blah"
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(422)
        expect(User.count).to eq(user_count_before)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["errors"]).not_to be_empty
      end
    end

    context "invalid: existing email" do
      let!(:other_orga) { create(:organisation) }
      let!(:existing_user) { create(:user, email: "jean@jacques.fr") }
      it "should not work" do
        user_count_before = User.count
        post(
          api_v1_users_path,
          params: {
            organisation_ids: [organisation.id],
            first_name: "Jean",
            last_name: "Jacques",
            email: "jean@jacques.fr"
          },
          headers: api_auth_headers_for_agent(agent)
        )
        expect(response.status).to eq(422)
        expect(User.count).to eq(user_count_before)
        response_parsed = JSON.parse(response.body)
        expect(response_parsed["errors"]).not_to be_empty
        expect(response_parsed["errors"]["email"].first).to \
          eq({ "error" => "taken", "value" => "jean@jacques.fr", "id" => existing_user.id })
      end
    end
  end
end
