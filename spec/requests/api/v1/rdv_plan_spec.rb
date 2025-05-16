RSpec.describe "RDV Plan API" do
  let!(:oauth_token) do
    create(:access_token, resource_owner_id: agent.id, application:)
  end
  let(:headers) do
    {
      "Content-Type": "application/json",
      Authorization: "Bearer #{oauth_token.plaintext_token}",
    }
  end
  let(:application) do
    create(:oauth_application,
           name: "Démarches Simplifiées",
           redirect_uri: "http://localhost:4567/omniauth/rdvservicepublic/callback\nhttp://demo.demarches-simplifiees.fr/omniauth/rdvservicepublic/callback",
           post_logout_redirect_uri: "http://localhost:4567/")
  end

  let(:agent) do
    create(:agent, basic_role_in_organisations: [create(:organisation)])
  end

  describe "#create" do
    let(:params) do
      {
        user: {
          first_name: "Francis",
          last_name: "Factice",
        },
      }
    end

    context "when the user doesn't already exist" do
      it "creates the user and the rdv plan" do
        expect do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
        end.to change(User, :count).by(1)
        rdv_plan = RdvPlan.last
        expect(rdv_plan.planning_agent).to eq agent
        expect(rdv_plan.user).to have_attributes(
          first_name: "Francis",
          last_name: "Factice"
        )
      end
    end

    context "when passing a user id" do
      let(:params) do
        { user: { id: user.id } }
      end

      context "when the user is not in any of the agent's organisations" do
        let(:user) do
          create(:user, organisations: [other_organisation])
        end
        let(:other_organisation) { create(:organisation) }

        it "raises an error" do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
          expect(RdvPlan.last).to be_nil
          expect(response.status).to eq 403
        end
      end

      context "when the user is in one of the agent's organisations" do
        let(:user) do
          create(:user, organisations: [agent.organisations.last])
        end

        it "creates the rdv plan with the user" do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
          expect(response.status).to eq 201
          expect(User.all.to_a).to eq [user]
          expect(RdvPlan.last.user).to eq user
        end
      end
    end

    context "when some of the params are missing" do
      let(:params) do
        { user: { first_name: "Francis" } }
      end

      it "returns an error message and doesn't create the rdv plan" do
        post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
        expect(RdvPlan.last).to be_nil
        expect(User.last).to be_nil
        expect(response.status).to eq 422
        expect(parsed_response_body["errors"]["last_name"]).to be_present
      end
    end

    context "when passing a user email" do
      let(:params) do
        { user: { email: "francis@factice.com", first_name: "Francois" } }
      end
      let!(:user) do
        create(:user, email: "francis@factice.com", organisations: [])
      end

      it "creates the rdv plan with the user, because we don't allow multiple users with the same email" do
        post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
        expect(response.status).to eq 201
        expect(User.all.to_a).to eq [user]
        expect(RdvPlan.last.user).to eq user
      end

      context "when the email is un uppercase" do
        let(:params) do
          { user: { email: "FRANCIS@FACTICE.COM", first_name: "Francois" } }
        end

        it "creates the rdv plan with the existing user" do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
          expect(response.status).to eq 201
          expect(User.all.to_a).to eq [user]
          expect(RdvPlan.last.user).to eq user
        end
      end
    end

    context "when passing all possible params" do
      let(:params) do
        {
          user: {
            first_name: "Francis",
            last_name: "Factice",
            email: "francis@factice.org",
            phone_number: "0611223344",
            address: "21 rue des Ardennes, 75019 Paris",
            birth_date: "1990-12-31",
          },
          return_url: "https://demo.demarches-simplifiees.fr/callback/123",
        }
      end

      it "creates the user and the rdv plan with all the attributes" do
        expect do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
        end.to change(User, :count).by(1)
        rdv_plan = RdvPlan.last
        expect(rdv_plan).to have_attributes(
          planning_agent: agent,
          return_url: "https://demo.demarches-simplifiees.fr/callback/123",
          oauth_application_id: application.id
        )

        expect(rdv_plan.user).to have_attributes(
          first_name: "Francis",
          last_name: "Factice",
          email: "francis@factice.org",
          phone_number: "0611223344",
          address: "21 rue des Ardennes, 75019 Paris",
          birth_date: Date.parse("1990-12-31")
        )
      end
    end

    context "when the agent hasn't configured an organisation yet" do
      let(:agent) { create(:agent, basic_role_in_organisations: []) }

      context "and the instance is RDV Service Public" do
        stub_env_with(
          AGENT_CONNECT_RDVSP_CLIENT_ID: "ec41582-1d60-4f11-a63b-d8abaece16aa"
        )
        it "shows a url with the correct domain name" do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
          expect(parsed_response_body.dig("rdv_plan", "url")).to include("www.rdv-mairie-test.localhost")
        end
      end
    end
  end

  describe "#show" do
    context "when the rdv_plan belongs to a different user" do
      let(:rdv_plan) do
        create(:rdv_plan, planning_agent: create(:agent))
      end

      it "returns an error" do
        get "/api/v1/rdv_plans/#{rdv_plan.id}", headers: headers, params: {}, as: :json
        expect(response.status).to eq 404
      end
    end
  end
end
