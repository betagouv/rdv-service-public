RSpec.describe Admin::Organisations::ConfigurationsController, type: :controller do
  before { request.env["devise.mapping"] = Devise.mappings[:agent] }

  describe "GET #show" do
    specify "un agent basique a accès" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      sign_in agent
      get :show, params: { organisation_id: organisation.id }
      expect(response).to be_successful
    end

    specify "un agent admin a accès" do
      organisation = create(:organisation)
      agent = create(:agent, admin_role_in_organisations: [organisation])
      sign_in agent
      get :show, params: { organisation_id: organisation.id }
      expect(response).to be_successful
    end

    specify "un agent qui n'est pas dans l'orga n'a pas accès" do
      organisation = create(:organisation)
      agent = create(:agent, basic_role_in_organisations: [create(:organisation)])
      sign_in agent
      get :show, params: { organisation_id: organisation.id }
      expect(response).to redirect_to(authenticated_agent_root_url)
    end
  end
end
