RSpec.describe Agent, type: :model do
  describe "#soft_delete" do
    context "with remaining organisations attached" do
      let(:organisation) { create(:organisation) }
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      it "raises" do
        expect { agent.soft_delete }.to raise_error SoftDeleteError
      end
    end

    context "without organisations" do
      let!(:agent) { create(:agent) }

      it "marks agent as soft deleted" do
        agent.soft_delete
        expect(agent.deleted_at).to be_present
      end
    end

    it "keep old mail in an `email_original` attribute" do
      agent = create(:agent, email: "karim@le64.fr", organisations: [])
      create(:rdv, agents: [agent])
      agent.soft_delete
      expect(agent.email_original).to eq("karim@le64.fr")
    end

    it "prepend deleted_ to inclusion_connect_open_id_sub" do
      agent = create(:agent, email: "karim@le64.fr", inclusion_connect_open_id_sub: "123456", organisations: [])
      create(:rdv, agents: [agent])
      agent.soft_delete
      expect(agent.inclusion_connect_open_id_sub).to eq("deleted_123456")
    end

    it "update mail with a unique value" do
      agent = create(:agent, basic_role_in_organisations: [])
      create(:rdv, agents: [agent])
      agent.soft_delete
      expect(agent.email).to eq("agent_#{agent.id}@deleted.rdv-solidarites.fr")
    end

    it "update UID with a unique value" do
      agent = create(:agent, basic_role_in_organisations: [])
      create(:rdv, agents: [agent])
      agent.soft_delete
      expect(agent.uid).to eq("agent_#{agent.id}@deleted.rdv-solidarites.fr")
    end

    it "delete associations" do
      territory = create(:territory)
      create(:agent_territorial_role, territory: territory, agent: create(:agent)) # le territoire doit avoir au moins un admin
      agent = create(:agent, basic_role_in_organisations: [])

      create(:absence, agent: agent)
      create(:plage_ouverture, agent: agent)
      agent.services << create(:service)
      create(:agent_territorial_access_right, agent: agent)
      create(:agent_territorial_role, agent: agent, territory: territory)
      agent.teams << create(:team)
      create(:referent_assignation, agent: agent)
      create(:sector_attribution, agent: agent)

      agent.soft_delete
      agent.reload

      expect(agent.absences).to be_empty
      expect(agent.plage_ouvertures).to be_empty
      expect(agent.services).to be_empty
      expect(agent.agent_territorial_access_rights).to be_empty
      expect(agent.territorial_roles).to be_empty
      expect(agent.teams).to be_empty
      expect(agent.referent_assignations).to be_empty
      expect(agent.sector_attributions).to be_empty
    end
  end

  describe "password validations" do
    it "provide the agent with explanations" do
      agent = build(:agent)

      agent.password = "123"
      agent.validate
      expected_error_messages = [
        "Pour assurer la sécurité de votre compte, votre mot de passe doit faire au moins 12 caractères",
        "Votre mot de passe doit comporter au moins une majuscule.",
        "Votre mot de passe doit comporter au moins un caractère spécial, par exemple un signe de ponctuation.",
      ]
      expect(agent.errors).to match_array(expected_error_messages)

      agent.password = "123!M"
      agent.validate
      expect(agent.errors).to match_array(["Pour assurer la sécurité de votre compte, votre mot de passe doit faire au moins 12 caractères"])

      agent.password = "123!Merci c'est assez long"
      agent.validate
      expect(agent).to be_valid
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
      expect(agent.multiple_organisations_access?).to be(true)
    end

    it "return false when agent allow to access multiple organisations" do
      agent = create(:agent, organisations: [create(:organisation)])
      expect(agent.multiple_organisations_access?).to be(false)
    end
  end

  describe "last_name validation" do
    let!(:agent) { build(:agent) }

    it "can be bypassed when needed" do
      expect(agent).to be_valid
      agent.last_name = nil
      expect(agent).not_to be_valid

      agent.errors.clear

      agent.allow_blank_name = true
      expect(agent).to be_valid
    end
  end

  describe "first_name validation" do
    let!(:agent) { build(:agent) }

    it "can be bypassed when needed" do
      expect(agent).to be_valid
      agent.first_name = nil
      expect(agent).not_to be_valid

      agent.errors.clear

      agent.allow_blank_name = true
      expect(agent).to be_valid
    end

    context "for an intervenant" do
      let!(:organisation) { create(:organisation) }
      let!(:agent_admin) { create(:agent, admin_role_in_organisations: [organisation]) }
      let(:agent_intervenant) { build(:agent, :intervenant, organisations: [organisation]) }

      it "is never needed" do
        agent_intervenant.first_name = nil
        expect(agent_intervenant).to be_valid
      end
    end
  end
end
