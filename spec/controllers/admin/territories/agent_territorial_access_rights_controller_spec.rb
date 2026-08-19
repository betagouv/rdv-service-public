# Ces specs de permissions complètent les specs de features de spec/features/territory_admins/territory_admin_can_manage_agents_spec.rb

RSpec.describe Admin::Territories::AgentTerritorialAccessRightsController, type: :controller do
  let!(:territory) { create(:territory).tap { |t| t.agent_territorial_access_rights.create!(agent: create(:agent), territory_admin: true) } }
  let(:organisation) { create(:organisation, territory: territory) }

  describe "PATCH #update" do
    context "when the current agent is territory admin" do
      let(:current_agent) { create(:agent, admin_in_territories: [territory]) }
      let(:target_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before { sign_in current_agent }

      it "allows granting territory_admin to another agent" do
        patch :update, params: {
          territory_id: territory.id, id: target_agent.id,
          agent_territorial_access_right: { territory_admin: "1" },
        }

        expect(target_agent.reload.territorial_admin_in?(territory)).to be true
        expect(response).to redirect_to(edit_admin_territory_agent_path(territory, target_agent))
        expect(flash[:success]).to be_present
      end

      it "allows revoking territory_admin from another admin, if not the last one" do
        create(:agent_territorial_access_right, :territory_admin, agent: target_agent, territory: territory)

        patch :update, params: {
          territory_id: territory.id, id: target_agent.id,
          agent_territorial_access_right: { territory_admin: "0" },
        }

        expect(target_agent.reload.territorial_admin_in?(territory)).to be false
        expect(flash[:success]).to be_present
      end

      it "does not allow removing the last territory admin" do
        solo_admin_territory = create(:territory)
        solo_admin = create(:agent, admin_in_territories: [solo_admin_territory])
        sign_in solo_admin

        expect do
          patch :update, params: {
            territory_id: solo_admin_territory.id, id: solo_admin.id,
            agent_territorial_access_right: { territory_admin: "0" },
          }
        end.not_to change { solo_admin.reload.territorial_admin_in?(solo_admin_territory) }

        expect(flash[:error]).to eq("Il doit toujours y avoir au moins un agent responsable par espace")
      end

      it "does not allow a territory admin, without allow_to_manage_access_rights, to also change the 3 specific rights" do
        patch :update, params: {
          territory_id: territory.id, id: target_agent.id,
          agent_territorial_access_right: { territory_admin: "1", allow_to_manage_teams: "1" },
        }

        expect(response).to redirect_to(authenticated_agent_root_url)
        expect(flash[:error]).to eq(I18n.t("pundit.default"))
        target_agent.reload
        expect(target_agent.territorial_admin_in?(territory)).to be false
        expect(target_agent.access_rights_for_territory(territory)&.allow_to_manage_teams?).to be_falsey
      end
    end

    context "when the current agent only has allow_to_manage_access_rights" do
      let(:current_agent) { create(:agent) }
      let(:target_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before do
        create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_access_rights: true)
        sign_in current_agent
      end

      it "allows editing the 3 specific rights of another agent" do
        create(:agent_territorial_access_right, agent: target_agent, territory: territory)

        patch :update, params: {
          territory_id: territory.id, id: target_agent.id,
          agent_territorial_access_right: { allow_to_manage_teams: "1", allow_to_invite_agents: "1" },
        }

        access_right = target_agent.reload.access_rights_for_territory(territory)
        expect(access_right.allow_to_manage_teams?).to be true
        expect(access_right.allow_to_invite_agents?).to be true
        expect(flash[:success]).to be_present
      end

      it "does not allow granting territory_admin" do
        create(:agent_territorial_access_right, agent: target_agent, territory: territory)

        patch :update, params: {
          territory_id: territory.id, id: target_agent.id,
          agent_territorial_access_right: { territory_admin: "1" },
        }

        expect(target_agent.reload.territorial_admin_in?(territory)).to be false
        expect(flash[:error]).to be_present
      end
    end

    context "when the current agent only has allow_to_manage_teams" do
      let(:current_agent) { create(:agent) }
      let(:target_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before do
        create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_teams: true)
        create(:agent_territorial_access_right, agent: target_agent, territory: territory)
        sign_in current_agent
      end

      it "does not allow editing another agent's specific rights" do
        patch :update, params: {
          territory_id: territory.id, id: target_agent.id,
          agent_territorial_access_right: { allow_to_manage_teams: "1" },
        }

        expect(target_agent.reload.access_rights_for_territory(territory).allow_to_manage_teams?).to be false
        expect(flash[:error]).to be_present
      end
    end
  end
end
