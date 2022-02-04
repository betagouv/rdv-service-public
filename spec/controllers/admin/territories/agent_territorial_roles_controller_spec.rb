# frozen_string_literal: true

describe Admin::Territories::AgentTerritorialRolesController, type: :controller do
  render_views

  let!(:territory) { create(:territory, departement_number: "62") }
  let!(:organisation) { create(:organisation, territory: territory) }

  before do
    sign_in agent
  end

  describe "#index" do
    context "with a few other agents" do
      let!(:territory2) { create(:territory, departement_number: "64") }
      let!(:agent) do
        create(
          :agent,
          first_name: "Johnny",
          last_name: "LILOU",
          basic_role_in_organisations: [organisation],
          role_in_territories: [territory, territory2]
        )
      end
      let!(:agent2) do
        create(
          :agent,
          first_name: "Lisa",
          last_name: "SOULAY",
          basic_role_in_organisations: [organisation],
          role_in_territories: [territory, territory2]
        )
      end
      let!(:agent_not_territorial_admin) do
        create(
          :agent,
          first_name: "Gina",
          last_name: "RICCIOTI",
          admin_role_in_organisations: [organisation]
        )
      end
      let!(:agent_in_other_territory) do
        create(
          :agent,
          first_name: "Doctor",
          last_name: "JOHN",
          admin_role_in_organisations: [organisation],
          role_in_territories: [territory2]
        )
      end

      it "lists only territorial agents" do
        get :index, params: { territory_id: territory.id }
        expect(response).to be_successful
        expect(response.body).to include("Johnny LILOU")
        expect(response.body).to include("Lisa SOULAY")
        expect(response.body).not_to include("Gina RICCIOTI")
        expect(response.body).not_to include("Doctor JOHN")
      end
    end

    context "non-territorial admin" do
      let!(:agent) do
        create(
          :agent,
          first_name: "Johnny",
          last_name: "LILOU",
          basic_role_in_organisations: [organisation]
        )
      end

      it "lists no one" do
        get :index, params: { territory_id: territory.id }
        expect(response).to be_successful
        expect(response.body).not_to include("Johnny LILOU")
      end
    end
  end

  describe "#new" do
    context "territorial admin agent signed in" do
      let!(:agent) do
        create(
          :agent,
          first_name: "Johnny",
          last_name: "LILOU",
          basic_role_in_organisations: [organisation],
          role_in_territories: [territory]
        )
      end
      let!(:other_agent_already_territorial_admin) do
        create(
          :agent,
          first_name: "Gino",
          last_name: "FINOL",
          basic_role_in_organisations: [organisation],
          role_in_territories: [territory]
        )
      end
      let!(:other_agent_not_yet_territorial_admin) do
        create(
          :agent,
          first_name: "Rizlane",
          last_name: "TERRY",
          basic_role_in_organisations: [organisation]
        )
      end

      it "displays form only with agents who are not yet territorial admins" do
        get :new, params: { territory_id: territory.id }
        expect(response).to be_successful
        expect(response.body).not_to include("LILOU Johnny")
        expect(response.body).not_to include("FINOL Gino")
        expect(response.body).to include("TERRY Rizlane")
      end
    end

    context "agent signed in is not territorial admin" do
      let!(:agent) do
        create(
          :agent,
          first_name: "Johnny",
          last_name: "LILOU",
          basic_role_in_organisations: [organisation]
        )
      end

      it "throws unauthorized error" do
        get :new, params: { territory_id: territory.id }
        expect(response).not_to be_successful
      end
    end
  end

  describe "#destroy" do
    subject do
      delete :destroy, params: { territory_id: territory.id, id: target_agent_territorial_role.id }
    end

    let!(:target_agent) do
      create(
        :agent,
        first_name: "Gino",
        last_name: "FINOL",
        basic_role_in_organisations: [organisation]
      )
    end
    let!(:target_agent_territorial_role) do
      create(:agent_territorial_role, agent: target_agent, territory: territory)
    end

    context "territorial admin agent signed in" do
      let!(:agent) do
        create(
          :agent,
          first_name: "Johnny",
          last_name: "LILOU",
          basic_role_in_organisations: [organisation],
          role_in_territories: [territory]
        )
      end

      it "destroys territorial role" do
        subject
        expect(response).to redirect_to(admin_territory_agent_territorial_roles_path(territory))
        expect(target_agent.reload.territorial_roles).to be_empty
      end
    end

    context "agent signed in is not territorial admin" do
      let!(:agent) do
        create(
          :agent,
          first_name: "Johnny",
          last_name: "LILOU",
          basic_role_in_organisations: [organisation]
        )
      end

      it "does not destroy territorial role" do
        subject
        expect(response).not_to be_successful
        expect(target_agent.reload.territorial_roles).not_to be_empty
      end
    end
  end
end
