# frozen_string_literal: true

describe Agent, type: :model do
  describe "#destroy" do
    context "with remaining organisations attached" do
      let(:organisation) { create(:organisation) }
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      it "aborts destruction" do
        expect { agent.destroy }.to raise_error(ActiveRecord::InvalidForeignKey)
        agent.reload # does not crash, so agent was not desrtroyed
      end
    end

    context "without organisations" do
      let!(:agent) { create(:agent) }

      it "destroys the agent" do
        agent.destroy
        expect { agent.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "password validations" do
    let(:organisation) { create(:organisation) }

    let(:agent) do
      create(:agent, admin_role_in_organisations: [organisation]).reload # The reload makes sure the role is in memory
    end

    xit "has only one validation for password length" do
      # Actuellement, ce test ne passe pas parce la validation est exécutée deux fois :
      # - une fois sur agent.password
      # - une fois sur agent.roles.agent.password
      # La deuxième validation est causée par le fait qu'on a un cycle de accepts_nested_attributes_for de agent, vers roles, puis à nouveau vers l'agent.
      # J'ai essayé d'ajouter un inverse_of sur le has_many, mais sans succès.
      # Pour le moment, cette double validation est contournée en dupliquant les clés de traductions des erreurs de agent vers agents/roles/agent, puis en faisant un uniq
      # sur les messages d'erreur.
      agent.password = "123"
      agent.validate
      expect(agent.errors.count).to eq(1)
    end
  end

  describe "#available_referents_for" do
    it "returns empty array without agents" do
      user = build(:user, referent_agents: [])
      expect(described_class.available_referents_for(user)).to eq([])
    end

    it "returns agent that not already referents array without agents" do
      agent = create(:agent)
      already_referent = create(:agent)
      user = create(:user, referent_agents: [already_referent])
      expect(described_class.available_referents_for(user)).to eq([agent])
    end
  end

  describe "#update_unknown_past_rdv_count!" do
    it "update with 0 if no past RDV" do
      agent = create(:agent)
      agent.update_unknown_past_rdv_count!
      expect(agent.reload.unknown_past_rdv_count).to eq(0)
    end

    it "update with 1 with one past RDV" do
      now = Time.zone.parse("20211123 10:45")
      travel_to(now)
      agent = create(:agent)
      create(:rdv, starts_at: now - 1.day, status: :unknown, agents: [agent])
      agent.update_unknown_past_rdv_count!
      expect(agent.reload.unknown_past_rdv_count).to eq(1)
    end
  end

  describe "#to_s" do
    it "return Validay Martine" do
      agent = build(:agent, last_name: "Validay", first_name: "Martine")
      expect(agent.to_s).to eq("Martine Validay")
    end
  end

  describe "#access_rights_for_territory" do
    it "returns nil when no access_rights founed" do
      territory = create(:territory)
      agent = create(:agent, organisations: [create(:organisation, territory: territory)])
      expect(agent.access_rights_for_territory(territory)).to be_nil
    end

    it "returns agent's agent_territorial_access_rights for given territorial" do
      territory = create(:territory)
      agent = create(:agent, organisations: [create(:organisation, territory: territory)])
      access_right = create(:agent_territorial_access_right, allow_to_manage_teams: true, agent: agent, territory: territory)
      expect(agent.access_rights_for_territory(territory)).to eq(access_right)
    end
  end

  describe "#multiple_organisations_access?" do
    it "return true with agent with 2 organisations" do
      agent = create(:agent, organisations: create_list(:organisation, 2))
      expect(agent.multiple_organisations_access?).to eq(true)
    end

    it "return false when agent allow to access multiple organisations" do
      agent = create(:agent, organisations: [create(:organisation)])
      expect(agent.multiple_organisations_access?).to eq(false)
    end
  end

  describe "last_name and first_name validations" do
    context "when agent is an intervenant" do
      let!(:organisation) { create(:organisation) }
      let!(:agent_admin) { create(:agent, admin_role_in_organisations: [organisation]) }
      let(:agent_intervenant) { build(:agent, :intervenant, organisations: [organisation]) }

      it "validates presence of last_name only on create" do
        agent_intervenant.last_name = nil
        agent_intervenant.first_name = nil
        agent_intervenant.valid?
        expect(agent_intervenant.errors.full_messages.uniq.to_sentence).to eq("Nom d’usage doit être rempli(e)")
      end

      it "validates presence of last_name only on update" do
        agent_intervenant.last_name = "jesuisintervenant"
        agent_intervenant.save
        agent_intervenant.last_name = nil
        agent_intervenant.first_name = nil
        agent_intervenant.valid?
        expect(agent_intervenant.errors.full_messages.uniq.to_sentence).to eq("Nom d’usage doit être rempli(e)")
      end
    end

    context "when agent is not an intervenant" do
      let!(:organisation) { create(:organisation) }
      let!(:agent_admin) { build(:agent, admin_role_in_organisations: [organisation]) }

      it "does not validates presence of last_name and first_name on create" do
        # On Agent creation first_name and last_name are leave blank for invited agent to fill them later
        agent_admin.last_name = nil
        agent_admin.first_name = nil
        agent_admin.valid?
        expect(agent_admin.email).not_to be_nil
        expect(agent_admin.errors).to be_empty
      end

      it "validates presence of last_name and first_name on update" do
        agent_admin.last_name = "ancien last name"
        agent_admin.first_name = "ancien first name"
        agent_admin.save
        agent_admin.last_name = nil
        agent_admin.first_name = nil
        agent_admin.valid?
        expect(agent_admin.errors[:last_name]).to include("doit être rempli(e)")
        expect(agent_admin.errors[:first_name]).to include("doit être rempli(e)")
      end
    end
  end
end
