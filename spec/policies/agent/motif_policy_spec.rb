# rubocop:disable RSpec/PredicateMatcher
RSpec.describe Agent::MotifPolicy do
  subject { described_class }

  let(:motif) { create(:motif) }

  context "for a basic agent of the same service" do
    let(:agent) { create(:agent, basic_role_in_organisations: [motif.organisation], service: motif.service) }

    it "allows seeing but not modifying the motif" do
      policy = described_class.new(agent, motif)
      expect(policy.show?).to be_truthy

      expect(policy.new?).to be_falsey
      expect(policy.create?).to be_falsey
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
      expect(policy.destroy?).to be_falsey

      expect(policy.versions?).to be_falsey
    end
  end

  context "for a basic agent of a different service" do
    let(:agent) { create(:agent, basic_role_in_organisations: [motif.organisation], service: create(:service)) }

    it "doesn't allow seeing or modifying the motif" do
      policy = described_class.new(agent, motif)
      expect(policy.show?).to be_falsey

      expect(policy.new?).to be_falsey
      expect(policy.create?).to be_falsey
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
      expect(policy.destroy?).to be_falsey

      expect(policy.versions?).to be_falsey
    end
  end

  context "for a secretaire" do
    let(:agent) { create(:agent, basic_role_in_organisations: [motif.organisation], service: create(:service, :secretariat)) }

    it "allows seeing but not modifying the motif" do
      policy = described_class.new(agent, motif)
      expect(policy.show?).to be_truthy

      expect(policy.new?).to be_falsey
      expect(policy.create?).to be_falsey
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
      expect(policy.destroy?).to be_falsey

      expect(policy.versions?).to be_falsey
    end
  end

  context "for an organisation admin" do
    let(:agent) { create(:agent, admin_role_in_organisations: [motif.organisation], service: create(:service)) }

    it "allows seeing and modifying the motif" do
      policy = described_class.new(agent, motif)
      expect(policy.show?).to be_truthy

      expect(policy.new?).to be_truthy
      expect(policy.create?).to be_truthy
      expect(policy.edit?).to be_truthy
      expect(policy.update?).to be_truthy
      expect(policy.destroy?).to be_truthy

      expect(policy.versions?).to be_truthy
    end
  end

  context "for the admin of a different organisation" do
    let(:agent) { create(:agent, admin_role_in_organisations: [create(:organisation)], service: motif.service) }

    it "allows nothing" do
      policy = described_class.new(agent, motif)
      expect(policy.show?).to be_falsey

      expect(policy.new?).to be_falsey
      expect(policy.create?).to be_falsey
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
      expect(policy.destroy?).to be_falsey

      expect(policy.versions?).to be_falsey
    end
  end

  describe Agent::MotifPolicy::ManageScope do
    context "when I am a territory admin" do
      let!(:territory_admin) { create(:agent, role_in_territories: [territory]) }

      let!(:territory) { create(:territory) }
      let!(:organisation_of_other_territory) { create(:organisation, territory: create(:territory)) }
      let!(:motif_in_my_territory) { create(:motif, organisation: create(:organisation, territory: territory)) }
      let!(:motif_in_other_territory) { create(:motif, organisation: organisation_of_other_territory) }

      it "includes all motifs from the territory's orgs" do
        manageable_motifs = described_class.apply(territory_admin, Motif.all)
        expect(manageable_motifs).to include(motif_in_my_territory)
        expect(manageable_motifs).not_to include(motif_in_other_territory)
      end
    end

    context "when I am an organisation admin" do
      let!(:organisation_admin) { create(:agent, admin_role_in_organisations: [organisation]) }

      let!(:territory) { create(:territory) }
      let!(:organisation) { create(:organisation, territory: territory) }
      let!(:motif_in_my_org) { create(:motif, organisation: organisation) }
      let!(:motif_in_other_org_of_my_territory) { create(:motif, organisation: create(:organisation, territory: territory)) }
      let!(:motif_in_other_territory) { create(:motif, organisation: create(:organisation, territory: create(:territory))) }

      it "includes motifs from my admin orgs, but not from other orgs" do
        manageable_motifs = described_class.apply(organisation_admin, Motif.all)
        expect(manageable_motifs).to include(motif_in_my_org)
        expect(manageable_motifs).not_to include(motif_in_other_org_of_my_territory)
        expect(manageable_motifs).not_to include(motif_in_other_territory)
      end
    end

    context "when I am a secretaire" do
      let!(:secretaire) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }

      let!(:territory) { create(:territory) }
      let!(:organisation) { create(:organisation, territory: territory) }
      let!(:motif_in_my_org) { create(:motif, organisation: organisation) }
      let!(:motif_in_other_org_of_my_territory) { create(:motif, organisation: create(:organisation, territory: territory)) }
      let!(:motif_in_other_territory) { create(:motif, organisation: create(:organisation, territory: create(:territory))) }

      it "does not allow me to manage any motif" do
        manageable_motifs = described_class.apply(secretaire, Motif.all)
        expect(manageable_motifs).to eq([])
      end
    end

    context "when I am a basic agent" do
      let!(:basic_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      let!(:territory) { create(:territory) }
      let!(:organisation) { create(:organisation, territory: territory) }
      let!(:motif_in_my_org) { create(:motif, organisation: organisation) }
      let!(:motif_in_other_org_of_my_territory) { create(:motif, organisation: create(:organisation, territory: territory)) }
      let!(:motif_in_other_territory) { create(:motif, organisation: create(:organisation, territory: create(:territory))) }

      it "does not allow me to manage any motif" do
        manageable_motifs = described_class.apply(basic_agent, Motif.all)
        expect(manageable_motifs).to eq([])
      end
    end
  end

  describe Agent::MotifPolicy::UseScope do
    context "when I am a territory admin" do
      let!(:territory_admin) { create(:agent, role_in_territories: [territory]) }

      let!(:territory) { create(:territory) }
      let!(:organisation_of_other_territory) { create(:organisation, territory: create(:territory)) }
      let!(:motif_in_my_territory) { create(:motif, organisation: create(:organisation, territory: territory)) }
      let!(:motif_in_other_territory) { create(:motif, organisation: organisation_of_other_territory) }

      it "includes all motifs from the territory's orgs" do
        manageable_motifs = described_class.apply(territory_admin, Motif.all)
        expect(manageable_motifs).to include(motif_in_my_territory)
        expect(manageable_motifs).not_to include(motif_in_other_territory)
      end
    end

    context "when I am an organisation admin" do
      let!(:organisation_admin) { create(:agent, admin_role_in_organisations: [organisation]) }

      let!(:territory) { create(:territory) }
      let!(:organisation) { create(:organisation, territory: territory) }
      let!(:motif_in_my_org) { create(:motif, organisation: organisation) }
      let!(:motif_in_other_org_of_my_territory) { create(:motif, organisation: create(:organisation, territory: territory)) }
      let!(:motif_in_other_territory) { create(:motif, organisation: create(:organisation, territory: create(:territory))) }

      it "includes motifs from my admin orgs, but not from other orgs" do
        manageable_motifs = described_class.apply(organisation_admin, Motif.all)
        expect(manageable_motifs).to include(motif_in_my_org)
        expect(manageable_motifs).not_to include(motif_in_other_org_of_my_territory)
        expect(manageable_motifs).not_to include(motif_in_other_territory)
      end
    end

    context "when I am a secretaire" do
      let!(:secretaire) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }

      let!(:territory) { create(:territory) }
      let!(:organisation) { create(:organisation, territory: territory) }
      let!(:motif_in_my_org) { create(:motif, organisation: organisation) }
      let!(:motif_in_other_org_of_my_territory) { create(:motif, organisation: create(:organisation, territory: territory)) }

      it "allows me to use motifs from my orgs, albeit basic" do
        manageable_motifs = described_class.apply(secretaire, Motif.all)
        expect(manageable_motifs).to include(motif_in_my_org)
        expect(manageable_motifs).not_to include(motif_in_other_org_of_my_territory)
      end
    end

    context "when I am a basic agent" do
      let!(:basic_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      let!(:territory) { create(:territory) }
      let!(:organisation) { create(:organisation, territory: territory) }
      let!(:motif_in_my_org_same_service) { create(:motif, organisation: organisation, service: basic_agent.services.first) }
      let!(:motif_in_my_org_other_service) { create(:motif, organisation: organisation, service: create(:service)) }

      it "allows me to use motifs from my orgs if they are from the ame service" do
        manageable_motifs = described_class.apply(basic_agent, Motif.all)
        expect(manageable_motifs).to include(motif_in_my_org_same_service)
        expect(manageable_motifs).not_to include(motif_in_my_org_other_service)
      end
    end
  end
end
# rubocop:enable RSpec/PredicateMatcher
