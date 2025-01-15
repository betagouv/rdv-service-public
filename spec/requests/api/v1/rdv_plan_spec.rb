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
    let(:agent) { create(:agent) }
    let!(:oauth_token) do
      create(:access_token, resource_owner_id: agent.id, application:)
    end

    context "when the user doesn't already exist" do
      it "creates the user and the rdv plan" do
        post "/api/v1/rdv_plans", headers: headers, params: params
      end
    end
  end
end
