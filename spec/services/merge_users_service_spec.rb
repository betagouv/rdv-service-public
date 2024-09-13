RSpec.describe MergeUsersService, type: :service do
  subject(:perform) { described_class.perform_with(user_target, user_to_merge, attributes_to_merge, organisation) }

  # defaults
  let!(:organisation) { create(:organisation) }
  let(:attributes_to_merge) { [] }
  let(:user_target) { create(:user, organisations: [organisation]) }
  let(:user_to_merge) { create(:user, organisations: [organisation]) }

  context "simply merge first_name" do
    let(:user_target) { create(:user, first_name: "Jean", last_name: "PAUL", notification_email: "jean@paul.fr", organisations: [organisation]) }
    let(:user_to_merge) { create(:user, first_name: "Francis", last_name: "DUTRONC", notification_email: "francis@dutronc.fr", organisations: [organisation]) }
    let(:attributes_to_merge) { [:first_name] }

    it "merges attributes" do
      perform
      user_target.reload
      expect(user_target.first_name).to eq("Francis")
      expect(user_target.last_name).to eq("PAUL")
      expect(user_target.email).to eq("jean@paul.fr")
      expect(user_to_merge.reload.deleted_at).to be_within(3.seconds).of(Time.zone.now)
    end
  end

  context "with rdvs in the same orga" do
    let(:user_target) { create(:user, organisations: [organisation]) }
    let(:user_to_merge) { create(:user, organisations: [organisation]) }
    let!(:rdv1) { create(:rdv, users: [user_target], organisation: organisation) }
    let!(:rdv2) { create(:rdv, users: [user_target], organisation: organisation) }
    let!(:rdv3) { create(:rdv, users: [user_to_merge], organisation: organisation) }
    let!(:rdv4) { create(:rdv, users: [user_to_merge], organisation: organisation) }

    it "moves RDVs to target user" do
      perform
      expect(rdv1.reload.users).to contain_exactly(user_target)
      expect(rdv2.reload.users).to contain_exactly(user_target)
      expect(rdv3.reload.users).to contain_exactly(user_target)
      expect(rdv4.reload.users).to contain_exactly(user_target)
      expect(user_to_merge.deleted_at).not_to be_nil
    end
  end

  context "with rdvs in different organisations" do
    let!(:organisation2) { create(:organisation) }
    let(:user_target) { create(:user, organisations: [organisation]) }
    let(:user_to_merge) { create(:user, organisations: [organisation, organisation2]) }
    let!(:rdv1) { create(:rdv, users: [user_target], organisation: organisation) }
    let!(:rdv2) { create(:rdv, users: [user_to_merge], organisation: organisation) }
    let!(:rdv3) { create(:rdv, users: [user_to_merge], organisation: organisation2) }

    it "moves RDVs to target user" do
      perform
      expect(rdv1.reload.users).to contain_exactly(user_target)
      expect(rdv2.reload.users).to contain_exactly(user_target)
      expect(rdv3.reload.users).to contain_exactly(user_to_merge)
      expect(user_to_merge.deleted_at).to be_nil
    end
  end

  context "with a rdv with both users already" do
    let!(:rdv) { create(:rdv, users: [user_target, user_to_merge], organisation: organisation) }

    it "justs remove user_to_merge from rdv" do
      perform
      expect(rdv.reload.users).to contain_exactly(user_target)
    end
  end

  context "with relatives" do
    let!(:relative1) { create(:user, responsible: user_target, organisations: [organisation]) }
    let!(:relative2) { create(:user, responsible: user_target, organisations: [organisation]) }
    let!(:relative3) { create(:user, responsible: user_to_merge, organisations: [organisation]) }
    let!(:relative4) { create(:user, responsible: user_to_merge, organisations: [organisation]) }

    it "moves relatives" do
      perform
      expect(user_target.relatives.count).to eq 4
      expect(relative1.reload.responsible).to eq user_target
      expect(relative2.reload.responsible).to eq user_target
      expect(relative3.reload.responsible).to eq user_target
      expect(relative4.reload.responsible).to eq user_target
    end
  end

  context "with file attentes for different rdvs" do
    let!(:rdv1) { create(:rdv, users: [user_target], organisation: organisation) }
    let!(:file_attente1) { create(:file_attente, user: user_target, rdv: rdv1) }
    let!(:rdv2) { create(:rdv, users: [user_to_merge], organisation: organisation) }
    let!(:file_attente2) { create(:file_attente, user: user_to_merge, rdv: rdv2) }

    it "moves file attente" do
      expect(FileAttente.count).to eq 2
      perform
      expect(FileAttente.count).to eq 2
      expect(user_target.file_attentes.count).to eq 2
      expect(file_attente2.reload.user).to eq user_target
      expect(file_attente2.reload.rdv.users).to contain_exactly(user_target)
    end
  end

  context "with file attentes for different orgas" do
    let!(:organisation2) { create(:organisation) }
    let!(:rdv1) { create(:rdv, users: [user_target], organisation: organisation) }
    let!(:file_attente1) { create(:file_attente, user: user_target, rdv: rdv1) }
    let!(:rdv2) { create(:rdv, users: [user_to_merge], organisation: organisation2) }
    let!(:file_attente2) { create(:file_attente, user: user_to_merge, rdv: rdv2) }

    it "does not move file attente from other orga" do
      expect(FileAttente.count).to eq 2
      perform
      expect(FileAttente.count).to eq 2
      expect(user_target.reload.file_attentes.count).to eq 1
      expect(user_to_merge.reload.file_attentes.count).to eq 1
      expect(file_attente2.reload.user).to eq user_to_merge
    end
  end

  context "with file attentes for the same rdvs" do
    let!(:rdv) { create(:rdv, users: [user_target], organisation: organisation) }
    let!(:file_attente1) { create(:file_attente, user: user_target, rdv: rdv) }
    let!(:file_attente2) { create(:file_attente, user: user_to_merge, rdv: rdv) }

    it "moves file attente" do
      expect(FileAttente.count).to eq 2
      perform
      expect(FileAttente.count).to eq 1
      expect(user_target.file_attentes.count).to eq 1
      expect(user_target.file_attentes.first.rdv).to eq rdv
    end
  end

  context "with different agents from same orga attached" do
    let!(:agent1) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:user_target) { create(:user, referent_agents: [agent1], organisations: [organisation]) }
    let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:user_to_merge) { create(:user, referent_agents: [agent2], organisations: [organisation]) }

    it "appends agents" do
      perform
      expect(user_target.referent_agents).to contain_exactly(agent1, agent2)
    end
  end

  context "with same agents" do
    let!(:agent1) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:user_target) { create(:user, referent_agents: [agent1, agent2], organisations: [organisation]) }
    let(:user_to_merge) { create(:user, referent_agents: [agent1, agent2], organisations: [organisation]) }

    it "does not do anything" do
      perform
      expect(user_target.referent_agents).to contain_exactly(agent1, agent2)
    end
  end

  context "target user doesn't have any agents yet" do
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:user_target) { create(:user, referent_agents: [], organisations: [organisation]) }
    let(:user_to_merge) { create(:user, referent_agents: [agent], organisations: [organisation]) }

    it "sets agent" do
      perform
      expect(user_target.referent_agents).to contain_exactly(agent)
    end
  end

  context "merged user doesn't have any agents yet" do
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:user_target) { create(:user, referent_agents: [agent], organisations: [organisation]) }
    let(:user_to_merge) { create(:user, referent_agents: [], organisations: [organisation]) }

    it "does not do anything" do
      perform
      expect(user_target.referent_agents).to contain_exactly(agent)
    end
  end

  context "merged user has an agent from another orga" do
    let!(:organisation2) { create(:organisation) }
    let!(:agent1) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation2]) }
    let(:user_target) { create(:user, referent_agents: [agent1], organisations: [organisation]) }
    let(:user_to_merge) { create(:user, referent_agents: [agent2], organisations: [organisation, organisation2]) }

    it "does not move the agent from the other orga anything" do
      perform
      expect(user_target.reload.referent_agents).to contain_exactly(agent1)
      expect(user_to_merge.reload.referent_agents).to contain_exactly(agent2)
    end
  end

  context "both users have notes" do
    before do
      user_target.update(notes: "Sympa")
      user_to_merge.update(notes: "thiquement")
    end

    it "preserves target by default" do
      perform
      expect(user_target.notes).to eq("Sympa")
    end

    context "when merging notes" do
      let(:attributes_to_merge) { [:notes] }

      it "overrides notes from merged user" do
        perform
        expect(user_target.notes).to eq("thiquement")
      end
    end
  end

  context "when one user is connected by FranceConnect" do
    it "keep FranceConnect attributes when merged user logged once with franceconnect" do
      user_to_merge = create(:user, logged_once_with_franceconnect: true, franceconnect_openid_sub: "unechainedecharacteres", organisations: [organisation])
      user_target = create(:user, organisations: [organisation])
      described_class.perform_with(user_target, user_to_merge, attributes_to_merge, organisation)
      user_target.reload
      expect(user_target.logged_once_with_franceconnect).to be_truthy
      expect(user_target.franceconnect_openid_sub).to eq("unechainedecharacteres")
    end

    it "keep FranceConnect attributes when user target logged once with franceconnect" do
      user_to_merge = create(:user, organisations: [organisation])
      user_target = create(:user, logged_once_with_franceconnect: true, franceconnect_openid_sub: "unechainedecharacteres", organisations: [organisation])
      described_class.perform_with(user_target, user_to_merge, attributes_to_merge, organisation)
      user_target.reload
      expect(user_target.logged_once_with_franceconnect).to be_truthy
      expect(user_target.franceconnect_openid_sub).to eq("unechainedecharacteres")
    end
  end

  context "when the participation was created by a prescripteur" do
    let(:user_target) { create(:user, organisations: [organisation]) }
    let(:user_to_merge) { create(:user, organisations: [organisation], created_through: :prescripteur) }
    let(:prescripteur) { create(:prescripteur) }
    let!(:participation) { build(:participation, user: user_to_merge) }
    let!(:rdv) { build(:rdv, organisation: organisation, participations: [participation], created_by: prescripteur) }

    before do
      participation.valid?
      rdv.save!
    end

    it "change user of the participation" do
      perform
      expect(rdv.participations.first.reload.user).to eq(user_target)
    end

    it "change users associated with the prescripteur" do
      perform
      expect(prescripteur.user).to eq(user_target)
    end
  end

  context "when target user is responsible for user to merge" do
    context "when target user has no responsible of her own" do
      let!(:user_target) { create(:user) }
      let!(:user_to_merge) { create(:user, responsible: user_target) }

      it "leaves no responsible in the resulting user" do
        described_class.perform_with(user_target, user_to_merge, [:responsible_id], organisation)
        expect(User.find_by(id: user_to_merge.id)).to be_nil # Expect user to be deleted
        expect(user_target.responsible).to be_nil
      end
    end

    context "when target user has a responsible user of her own" do
      let!(:responsible_of_target_user) { create(:user) }
      let!(:user_target) { create(:user, responsible: responsible_of_target_user) }
      let!(:user_to_merge) { create(:user, responsible: user_target) }

      it "keeps the responsible" do
        described_class.perform_with(user_target, user_to_merge, [], organisation)
        expect(User.find_by(id: user_to_merge.id)).to be_nil # Expect user to be deleted
        expect(user_target.responsible).to eq(responsible_of_target_user)
      end
    end
  end

  # Comportement spécifique au 92, voir :
  # https://github.com/betagouv/rdv-solidarites.fr/issues/3429
  context "when organisation's territory has visible_users_throughout_the_territory: true" do
    let!(:territory) { create(:territory, visible_users_throughout_the_territory: true) }
    let!(:organisation) { create(:organisation, territory: territory) }

    context "when both users belong to the current org" do
      let(:user_target) { create(:user, organisations: [organisation]) }
      let(:user_to_merge) { create(:user, organisations: [organisation]) }

      it "deletes the user to merge" do
        perform
        expect(user_target.reload.organisations).to eq([organisation])
        expect(UserProfile.find_by(user_id: user_to_merge.id)).to be_nil
        expect(User.find_by(id: user_to_merge.id)).to be_nil
      end
    end

    context "when they each belong to a different org" do
      let(:organisation2) { create(:organisation, territory: territory) }
      let(:user_target) { create(:user, organisations: [organisation]) }
      let(:user_to_merge) { create(:user, organisations: [organisation2]) }

      it "adds all organisations to the target user and deletes the user to merge" do
        perform
        expect(user_target.reload.organisations).to contain_exactly(organisation, organisation2)
        expect(UserProfile.find_by(user_id: user_to_merge.id)).to be_nil
        expect(User.find_by(id: user_to_merge.id)).to be_nil
      end
    end

    context "when they have some orgs in common" do
      let(:organisation2) { create(:organisation, territory: territory) }
      let(:organisation3) { create(:organisation, territory: territory) }
      let(:user_target) { create(:user, organisations: [organisation, organisation2]) }
      let(:user_to_merge) { create(:user, organisations: [organisation2, organisation3]) }

      it "adds all organisations to the target user and deletes the user to merge" do
        perform
        expect(user_target.reload.organisations).to contain_exactly(organisation, organisation2, organisation3)
        expect(UserProfile.find_by(user_id: user_to_merge.id)).to be_nil
        expect(User.find_by(id: user_to_merge.id)).to be_nil
      end
    end

    context "when they have some orgs in common and others from a different territory" do
      let(:other_territory) { create(:territory) }
      let(:organisation2) { create(:organisation, territory: territory) }
      let(:organisation3) { create(:organisation, territory: territory) }
      let(:organisation_in_other_territory) { create(:organisation, territory: other_territory) }
      let(:user_target) { create(:user, organisations: [organisation, organisation2]) }
      let(:user_to_merge) { create(:user, organisations: [organisation2, organisation3, organisation_in_other_territory]) }

      it "adds all organisations OF THE CURRENT TERRITORY to the target user and DOES NOT delete the user to merge" do
        perform
        expect(user_target.reload.organisations).to contain_exactly(organisation, organisation2, organisation3)
        expect(user_target.organisations).not_to include(organisation_in_other_territory)
        expect(UserProfile.where(user_id: user_to_merge.id).pluck(:organisation_id)).to eq([organisation_in_other_territory.id])
        expect(User.find_by(id: user_to_merge.id)).to eq(user_to_merge)
      end

      describe "RDVs" do
        let!(:rdv_in_same_territory) { create(:rdv, users: [user_to_merge], organisation: organisation2) }
        let!(:rdv_in_other_territory) { create(:rdv, users: [user_to_merge], organisation: organisation_in_other_territory) }

        it "moves RDVs of the current territory, not the others" do
          perform

          # RDV in current territory is moved to target user
          expect(rdv_in_same_territory.reload.organisation).to eq(organisation2)
          expect(rdv_in_same_territory.users).to eq([user_target])

          # RDV in other territory is NOT moved to target user
          expect(rdv_in_other_territory.reload.organisation).to eq(organisation_in_other_territory)
          expect(rdv_in_other_territory.users).to eq([user_to_merge])
        end
      end

      describe "files d'attente" do
        let!(:file_attente_in_same_territory) { create(:file_attente, user: user_to_merge, rdv: create(:rdv, organisation: organisation2)) }
        let!(:file_attente_in_other_territory) { create(:file_attente, user: user_to_merge, rdv: create(:rdv, organisation: organisation_in_other_territory)) }

        it "moves file d'attentes of the current territory, not the others" do
          perform

          expect(file_attente_in_same_territory.reload.user).to eq(user_target)
          expect(file_attente_in_other_territory.reload.user).to eq(user_to_merge)
        end
      end

      describe "referent agents" do
        let!(:referent_agent_from_same_territory) { create(:agent, organisations: [organisation2]) }
        let!(:referent_agent_from_other_territory) { create(:agent, organisations: [organisation_in_other_territory]) }

        before do
          user_to_merge.referent_agents.push(referent_agent_from_same_territory)
          user_to_merge.referent_agents.push(referent_agent_from_other_territory)
        end

        it "moves referents of the current territory, not the others" do
          perform

          expect(user_target.referent_agents).to include(referent_agent_from_same_territory)
          expect(user_target.referent_agents).not_to include(referent_agent_from_other_territory)
        end
      end
    end
  end
end
