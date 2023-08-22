# frozen_string_literal: true

describe AgentRole::IntervenantRoleChangeable, type: :concern do
  let!(:organisation) { create(:organisation) }
  let!(:current_agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  describe "#change_role_from_intervenant_and_invite" do
    let(:invitation_email) { "jesuisunagent@rdvsp.com" }

    context "when agent_role access_level is updated from intervenant to admin" do
      let!(:existing_agent) { create(:agent, email: "existing@agent.fr") }
      let!(:agent_user) { create(:agent, :intervenant, organisations: [organisation]) }
      let!(:agent_role) { agent_user.roles.first }

      it "does not update the requested agent_role if invitation email is invalid" do
        invalid_email = "invalid_email"
        agent_role.change_role_from_intervenant_and_invite(current_agent, invalid_email)
        expect(agent_role.errors.full_messages).to include("Email n'est pas valide")
        expect(agent_role.access_level).to eq("intervenant")
        expect(agent_role.agent.reload.email).to be_nil
        expect(agent_role.agent.uid).to be_nil
        expect(enqueued_jobs).to be_empty
      end

      it "does not update the requested agent_role if invitation email is nil" do
        nil_email = nil
        agent_role.change_role_from_intervenant_and_invite(current_agent, nil_email)
        expect(agent_role.errors.full_messages).to include("L'email d'invitation doit être rempli")
        expect(agent_role.access_level).to eq("intervenant")
        expect(agent_role.agent.reload.email).to be_nil
        expect(agent_role.agent.uid).to be_nil
        expect(enqueued_jobs).to be_empty
      end

      it "does not update the requested agent_role if invitation email is already taken" do
        agent_role.change_role_from_intervenant_and_invite(current_agent, existing_agent.email)
        expect(agent_role.errors.full_messages).to include("Email est déjà utilisé")
        expect(agent_role.access_level).to eq("intervenant")
        expect(agent_role.agent.reload.email).to be_nil
        expect(agent_role.agent.uid).to be_nil
        expect(enqueued_jobs).to be_empty
      end
    end

    context "when agent_role access_level is updated from admin to intervenant" do
      let!(:agent_user) { create(:agent, admin_role_in_organisations: [organisation]) }
      let!(:agent_role) { agent_user.reload.roles.first }

      it "updates the agent_role" do
        agent_role.access_level = "intervenant"
        agent_role.change_role_to_intervenant
        expect(agent_role.access_level).to eq("intervenant")
        expect(agent_role.agent).to have_attributes(
          email: nil,
          uid: nil,
          invitation_token: nil,
          invitation_accepted_at: nil,
          invitation_created_at: nil,
          invitation_sent_at: nil,
          invited_by_id: nil,
          invited_by_type: nil
        )
        expect(enqueued_jobs).to be_empty
      end

      it "show an error if agent_user belongs to more than one organisation" do
        agent_user.organisations << create(:organisation)
        agent_role.access_level = "intervenant"
        agent_role.change_role_to_intervenant
        expect(agent_role.errors.full_messages).to include("Un agent membre de plusieurs organisations ne peut pas avoir un statut d'intervenant")
        expect(agent_role.reload.access_level).to eq("admin")
        expect(enqueued_jobs).to be_empty
      end
    end
  end
end
