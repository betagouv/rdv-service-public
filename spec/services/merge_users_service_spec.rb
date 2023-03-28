# frozen_string_literal: true

describe MergeUsersService, type: :service do
  subject { described_class.perform_with(user_target, user_to_merge, attributes_to_merge, organisation) }

  # defaults
  let!(:organisation) { create(:organisation) }
  let(:attributes_to_merge) { [] }
  let(:user_target) { create(:user, organisations: [organisation]) }
  let(:user_to_merge) { create(:user, organisations: [organisation]) }

  context "simply merge first_name" do
    let(:user_target) { create(:user, first_name: "Jean", last_name: "PAUL", email: "jean@paul.fr", organisations: [organisation]) }
    let(:user_to_merge) { create(:user, first_name: "Francis", last_name: "DUTRONC", email: "francis@dutronc.fr", organisations: [organisation]) }
    let(:attributes_to_merge) { [:first_name] }

    it "merges attributes" do
      subject
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
      subject
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
      subject
      expect(rdv1.reload.users).to contain_exactly(user_target)
      expect(rdv2.reload.users).to contain_exactly(user_target)
      expect(rdv3.reload.users).to contain_exactly(user_to_merge)
      expect(user_to_merge.deleted_at).to be_nil
    end
  end

  context "with a rdv with both users already" do
    let!(:rdv) { create(:rdv, users: [user_target, user_to_merge], organisation: organisation) }

    it "justs remove user_to_merge from rdv" do
      subject
      expect(rdv.reload.users).to contain_exactly(user_target)
    end
  end

  context "with relatives" do
    let!(:relative1) { create(:user, responsible: user_target, organisations: [organisation]) }
    let!(:relative2) { create(:user, responsible: user_target, organisations: [organisation]) }
    let!(:relative3) { create(:user, responsible: user_to_merge, organisations: [organisation]) }
    let!(:relative4) { create(:user, responsible: user_to_merge, organisations: [organisation]) }

    it "moves relatives" do
      subject
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
      subject
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
      subject
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
      subject
      expect(FileAttente.count).to eq 1
      expect(user_target.file_attentes.count).to eq 1
      expect(user_target.file_attentes.first.rdv).to eq rdv
    end
  end

  context "with different agents from same orga attached" do
    let!(:agent1) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:user_target) { create(:user, agents: [agent1], organisations: [organisation]) }
    let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:user_to_merge) { create(:user, agents: [agent2], organisations: [organisation]) }

    it "appends agents" do
      subject
      expect(user_target.agents).to contain_exactly(agent1, agent2)
    end
  end

  context "with same agents" do
    let!(:agent1) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:user_target) { create(:user, agents: [agent1, agent2], organisations: [organisation]) }
    let(:user_to_merge) { create(:user, agents: [agent1, agent2], organisations: [organisation]) }

    it "does not do anything" do
      subject
      expect(user_target.agents).to contain_exactly(agent1, agent2)
    end
  end

  context "target user doesn't have any agents yet" do
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:user_target) { create(:user, agents: [], organisations: [organisation]) }
    let(:user_to_merge) { create(:user, agents: [agent], organisations: [organisation]) }

    it "sets agent" do
      subject
      expect(user_target.agents).to contain_exactly(agent)
    end
  end

  context "merged user doesn't have any agents yet" do
    let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:user_target) { create(:user, agents: [agent], organisations: [organisation]) }
    let(:user_to_merge) { create(:user, agents: [], organisations: [organisation]) }

    it "does not do anything" do
      subject
      expect(user_target.agents).to contain_exactly(agent)
    end
  end

  context "merged user has an agent from another orga" do
    let!(:organisation2) { create(:organisation) }
    let!(:agent1) { create(:agent, basic_role_in_organisations: [organisation]) }
    let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation2]) }
    let(:user_target) { create(:user, agents: [agent1], organisations: [organisation]) }
    let(:user_to_merge) { create(:user, agents: [agent2], organisations: [organisation, organisation2]) }

    it "does not move the agent from the other orga anything" do
      subject
      expect(user_target.reload.agents).to contain_exactly(agent1)
      expect(user_to_merge.reload.agents).to contain_exactly(agent2)
    end
  end

  context "both users have notes" do
    before do
      user_target.update(notes: "Sympa")
      user_to_merge.update(notes: "thiquement")
    end

    it "preserves target by default" do
      subject
      expect(user_target.notes).to eq("Sympa")
    end

    context "when merging notes" do
      let(:attributes_to_merge) { [:notes] }

      it "overrides notes from merged user" do
        subject
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

  context "when one of the users was created by a prescripteur" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user, created_through: :prescripteur) }
    let(:rdv) { create(:rdv, organisation: organisation) }
    let(:prescripteur) { create(:prescripteur) }

    before do
      create(:rdvs_user, rdv: rdv, user: user2, prescripteur: prescripteur)
    end

    it "changes the prescripteur to the target user" do
      expect do
        described_class.perform_with(user1, user2, attributes_to_merge, organisation)
      end.to change { prescripteur.reload.user }.from(user2).to(user1)
    end
  end
end
