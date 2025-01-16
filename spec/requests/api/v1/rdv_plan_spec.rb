RSpec.describe "RDV Plan API" do
  describe "#create" do
    let(:params) do
      {
        user: {
          first_name: "Francis",
          last_name: "Factice",
        },
      }
    end
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
        redirect_uri: "http://localhost:4567/omniauth/rdvservicepublic/callback",
        post_logout_redirect_uri: "http://localhost:4567/",
        logo_base64: ""
      )
    end
    let(:agent) do
      create(:agent, basic_role_in_organisations: [create(:organisation)])
    end

    before do
      create(:agent_territorial_access_right, agent: agent, territory: agent.organisations.last.territory)
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

      context "when the user is in a different territory" do
        let(:user) do
          create(:user, organisations: [organisation_from_other_territory])
        end
        let(:organisation_from_other_territory) { create(:organisation) }

        it "raises an error" do
          post "/api/v1/rdv_plans", headers: headers, params: params, as: :json
          expect(RdvPlan.last).to be_nil
          expect(response.status).to eq 403
        end
      end

      context "when the user is in one of the agent's territories" do
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
  end
end
