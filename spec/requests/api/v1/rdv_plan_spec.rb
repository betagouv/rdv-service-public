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
    Doorkeeper::Application.create!(
      name: "Démarches Simplifiées",
      uid: "fake_app_id",
      redirect_uri: "http://localhost:4567/omniauth/rdvservicepublic/callback\nhttp://demo.demarches-simplifiees.fr/omniauth/rdvservicepublic/callback",
      post_logout_redirect_uri: "http://localhost:4567/",
      logo_base64: ""
    )
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
          agent: agent,
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
  end

  describe "#show" do
    context "when there is a rdv" do
      let(:rdv_plan) do
        create(:rdv_plan, rdv: create(:rdv), planning_agent: agent)
      end

      it "returns the minimum information about the rdv" do
        get "/api/v1/rdv_plans/#{rdv_plan.id}", headers: headers, params: {}, as: :json
        expect(parsed_response_body.dig("rdv_plan", "rdv")).to match(
          {
            id: rdv_plan.rdv_id,
            status: "unknown",
          }
        )
      end
    end

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
