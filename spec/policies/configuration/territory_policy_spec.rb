# frozen_string_literal: true

describe Configuration::TerritoryPolicy, type: :policy do
  subject { described_class }

  let(:territory) { create(:territory) }
  let(:agent_territorial_context) { AgentTerritorialContext.new(agent, territory) }

  shared_examples "permit actions" do |*actions|
    actions.each do |action|
      permissions action do
        it { is_expected.to permit(agent_territorial_context, territory) }
      end
    end
  end

  shared_examples "not permit actions" do |*actions|
    actions.each do |action|
      permissions action do
        it { is_expected.not_to permit(agent_territorial_context, territory) }
      end
    end
  end

  describe "agent with" do
    context "no admin access to this territory and no access_rights" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory) }

      it_behaves_like "not permit actions",
                      :show?,
                      :update?,
                      :edit?,
                      :allow_to_manage_access_rights?,
                      :allow_to_invite_agents?,
                      :allow_to_manage_teams?,
                      :display_user_fields_configuration?,
                      :display_rdv_fields_configuration?,
                      :display_motif_fields_configuration?
    end

    context "admin access to this territory" do
      let(:territory) { create(:territory) }
      let(:agent) { create(:agent, role_in_territories: [territory]) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory) }

      it_behaves_like "permit actions",
                      :show?,
                      :update?,
                      :edit?,
                      :display_user_fields_configuration?,
                      :display_rdv_fields_configuration?,
                      :display_motif_fields_configuration?

      it_behaves_like "not permit actions",
                      :allow_to_manage_access_rights?,
                      :allow_to_invite_agents?,
                      :allow_to_manage_teams?
    end

    context "allowed to manage teams access right" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_manage_teams: true) }

      it_behaves_like "permit actions",
                      :show?,
                      :allow_to_manage_teams?

      it_behaves_like "not permit actions",
                      :update?,
                      :edit?,
                      :allow_to_manage_access_rights?,
                      :allow_to_invite_agents?,
                      :display_user_fields_configuration?,
                      :display_rdv_fields_configuration?,
                      :display_motif_fields_configuration?
    end

    context "allowed to manage access rights access right" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_manage_access_rights: true) }

      it_behaves_like "permit actions",
                      :show?,
                      :allow_to_manage_access_rights?

      it_behaves_like "not permit actions",
                      :update?,
                      :edit?,
                      :allow_to_manage_teams?,
                      :allow_to_invite_agents?,
                      :display_user_fields_configuration?,
                      :display_rdv_fields_configuration?,
                      :display_motif_fields_configuration?
    end

    context "allowed to invite agents access right" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_invite_agents: true) }

      it_behaves_like "permit actions",
                      :show?,
                      :allow_to_invite_agents?

      it_behaves_like "not permit actions",
                      :update?,
                      :edit?,
                      :allow_to_manage_access_rights?,
                      :allow_to_manage_teams?,
                      :display_user_fields_configuration?,
                      :display_rdv_fields_configuration?,
                      :display_motif_fields_configuration?
    end

    context "allowed to download metrics access right" do
      let(:agent) { create(:agent, role_in_territories: []) }
      let!(:access_rights) { create(:agent_territorial_access_right, agent: agent, territory: territory, allow_to_download_metrics: true) }

      it_behaves_like "permit actions",
                      :show?,
                      :allow_to_download_metrics?

      it_behaves_like "not permit actions",
                      :update?,
                      :edit?,
                      :allow_to_invite_agents?,
                      :allow_to_manage_access_rights?,
                      :allow_to_manage_teams?,
                      :display_user_fields_configuration?,
                      :display_rdv_fields_configuration?,
                      :display_motif_fields_configuration?
    end
  end
end
