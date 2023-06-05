# frozen_string_literal: true

describe Motif, type: :model do
  let(:motif_with_rdv) { create(:motif, :with_rdvs, organisation: organisation) }
  let(:secretariat) { create(:service, :secretariat) }
  let(:motif) { create(:motif, organisation: organisation) }
  let!(:organisation) { create(:organisation) }

  it "have a valid factory" do
    expect(build(:motif)).to be_valid
  end

  it "invalid without #RRGGBB format's color" do
    expect(build(:motif, color: "vert")).to be_invalid
    expect(build(:motif, color: "002233")).to be_invalid
    expect(build(:motif, color: "#002233")).to be_valid
  end

  describe "uniqueness" do
    subject { motif.dup }

    let(:service) { build(:service) }
    let(:motif) { create(:motif, name: "name", location_type: :home, service: service, organisation: organisation) }

    it do
      expect(subject).not_to be_valid
      expect(subject.errors.details).to eq({ name: [{ error: :taken, value: "name" }] })
      expect(subject.errors.full_messages.to_sentence).to eq "Nom est déjà utilisé pour un motif avec le même type de RDV."
    end
  end

  describe ".create when associated with secretariat" do
    let(:motif) { build(:motif, service: secretariat, organisation: organisation) }

    it { expect(motif).not_to be_valid }
  end

  describe "#soft_delete" do
    it "doesn't delete the motif with rdvs" do
      now = Time.zone.parse("2020-03-23 15h45")
      travel_to(now)
      motif.soft_delete
      motif_with_rdv.soft_delete
      expect(described_class.all).to eq [motif_with_rdv]
      expect(motif_with_rdv.reload.deleted_at).to eq(now)
    end

    context "when the motif only has a soft deleted rdv" do
      before do
        rdv = create(:rdv, motif: motif)
        rdv.soft_delete
      end

      it "soft deletes the motif" do
        motif.soft_delete
        expect(motif.deleted_at).not_to be_nil
      end
    end
  end

  describe "#available_motifs_for_organisation_and_agent" do
    subject { described_class.available_motifs_for_organisation_and_agent(motif.organisation, agent) }

    let(:service) { create(:service) }
    let!(:motif) { create(:motif, service: service, organisation: organisation) }
    let!(:motif2) { create(:motif, service: service, organisation: organisation) }
    let!(:motif3) { create(:motif, :for_secretariat, service: service, organisation: organisation) }
    let!(:motif4) { create(:motif, service: service, organisation: create(:organisation)) }
    let!(:motif5) { create(:motif, service: create(:service), organisation: organisation) }
    let(:plage_ouverture) { build(:plage_ouverture, agent: agent, organisation: organisation) }

    describe "for secretaire" do
      let(:agent) { create(:agent, :secretaire, basic_role_in_organisations: [organisation]) }

      it { is_expected.to contain_exactly(motif3) }
    end

    describe "for other service" do
      let(:agent) { create(:agent, service: service, basic_role_in_organisations: [organisation]) }

      it { is_expected.to contain_exactly(motif, motif2, motif3) }
    end

    describe "for admin" do
      let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

      it { is_expected.to contain_exactly(motif, motif2, motif3, motif5) }
    end

    describe "for secretary admin" do
      let(:agent) { create(:agent, :secretaire, admin_role_in_organisations: [organisation]) }

      it { is_expected.to contain_exactly(motif, motif2, motif3, motif5) }
    end
  end

  describe "#authorized_agents" do
    subject { motif.authorized_agents.to_a }

    let(:org1) { create(:organisation) }
    let!(:service_pmi) { create(:service, name: "PMI") }
    let!(:service_secretariat) { create(:service, name: Service::SECRETARIAT) }
    let!(:agent_pmi1) { create(:agent, basic_role_in_organisations: [org1], service: service_pmi) }
    let!(:agent_pmi2) { create(:agent, basic_role_in_organisations: [org1], service: service_pmi) }
    let!(:agent_secretariat1) { create(:agent, basic_role_in_organisations: [org1], service: service_secretariat) }
    let!(:motif) { create(:motif, service: service_pmi, organisation: org1) }

    it { is_expected.to match_array([agent_pmi1, agent_pmi2]) }

    context "motif is available for secretariat" do
      let!(:motif) { create(:motif, service: service_pmi, organisation: org1, for_secretariat: true) }

      it { is_expected.to match_array([agent_pmi1, agent_pmi2, agent_secretariat1]) }
    end

    context "agent from same service but different orga" do
      let(:org2) { create(:organisation) }
      let!(:agent_pmi3) { create(:agent, basic_role_in_organisations: [org2], service: service_pmi) }

      it { is_expected.not_to include(agent_pmi3) }
    end
  end

  describe "secretariat?" do
    it "return true if motif for_secretariat" do
      motif = build(:motif, for_secretariat: true, organisation: organisation)
      expect(motif.secretariat?).to be true
    end

    it "return false if motif for_secretariat" do
      motif = build(:motif, for_secretariat: false, organisation: organisation)
      expect(motif.secretariat?).to be false
    end
  end

  describe "visible_and_notified?" do
    it "vrai quand visible_type == visible_and_notified" do
      motif = build(:motif, :visible_and_notified)
      expect(motif.visible_and_notified?).to eq(true)
    end

    it "faux quand visible_type == visible_and_not_notified" do
      motif = build(:motif, :visible_and_not_notified)
      expect(motif.visible_and_notified?).to eq(false)
    end

    it "faux quand visible_type == invisible" do
      motif = build(:motif, :invisible)
      expect(motif.visible_and_notified?).to eq(false)
    end
  end

  describe "search_by_name_with_location_type" do
    context "some matching motif name + type" do
      subject { described_class.search_by_name_with_location_type("Rappel PMI-phone") }

      let!(:motif) { create(:motif, name: "Rappel PMI", location_type: :phone) }

      it { is_expected.to include(motif) }
    end

    context "no matching motif name" do
      subject { described_class.search_by_name_with_location_type("Rappel PMI-phone") }

      let!(:motif) { create(:motif, name: "Rien a voir", location_type: :phone) }

      it { is_expected.to be_empty }
    end

    context "nil param" do
      subject { described_class.search_by_name_with_location_type(nil) }

      let!(:motif) { create(:motif, name: "Rappel PMI", location_type: :phone) }

      it { is_expected.to be_empty }
    end
  end

  describe "motif de rdv collectif" do
    subject(:motif) { build(:motif, collectif: true, location_type: :home) }

    it "validates that a rdv collectif can't be at the user's home" do
      expect(motif).not_to be_valid
      expect(subject.errors.full_messages).to eq [
        "Les RDV collectifs doivent avoir lieu sur place.",
      ]
    end
  end

  describe "#start_booking_delay" do
    it "return now + 30 minutes when min_public_booking_delay is at default value" do
      now = Time.zone.parse("20220123 14:54")
      travel_to(now)
      motif = build(:motif, min_public_booking_delay: 1800)
      expect(motif.start_booking_delay).to eq(now + 1800.seconds)
    end

    it "return now + 7 days (in minutes) when min_public_booking_delay is set to one week" do
      now = Time.zone.parse("20220123 14:54")
      travel_to(now)
      motif = build(:motif, min_public_booking_delay: 1.week)
      expect(motif.start_booking_delay).to eq(now + 1.week)
    end
  end

  describe "#end_booking_delay" do
    it "return now + 3 months when max_public_booking_delay default value" do
      now = Time.zone.parse("20220123 14:54")
      travel_to(now)
      motif = build(:motif, min_public_booking_delay: 3.months.in_seconds)
      expect(motif.start_booking_delay).to eq(now + 3.months.in_seconds.seconds)
    end
  end

  describe "#booking_delay_range" do
    it "returns (now + min_public_booking_delay)..(now + max_public_booking_delay)" do
      now = Time.zone.parse("20220123 14:54")
      travel_to(now)
      motif = build(:motif, min_public_booking_delay: 30.minutes.in_seconds, max_public_booking_delay: 3.months.in_seconds)
      expect(motif.booking_delay_range).to eq((now + 30.minutes.in_seconds.seconds)..(now + 3.months.in_seconds.seconds))
    end
  end

  describe "#requires_lieu?" do
    it "returns false if the location_type doesn't require a lieu" do
      expect(build(:motif, :by_phone).requires_lieu?).to eq(false)
      expect(build(:motif, :at_home).requires_lieu?).to eq(false)
    end

    it "returns true if the location_type requires a lieu" do
      expect(build(:motif, :at_public_office).requires_lieu?).to eq(true)
    end
  end

  describe "cant update type when already used for a rdv" do
    it "valid when no RDV use this motif" do
      motif = create(:motif, location_type: "public_office")
      expect do
        motif.update(location_type: "phone")
      end.to change {
        motif.reload.location_type
      }.from("public_office").to("phone")
    end

    it "invalid when RDV use this motif" do
      motif = create(:motif, location_type: "public_office")
      create(:rdv, motif: motif)
      expect do
        motif.update(location_type: "phone")
      end.not_to change {
        motif.reload.location_type
      }
    end

    it "error with clear error message when RDV use this motif" do
      motif = create(:motif, location_type: "public_office")
      create(:rdv, motif: motif)
      motif.update(location_type: "phone")
      expect(motif.reload.errors.full_messages).to eq(["Type de RDV ne peut être modifié car le motif est utilisé pour un RDV"])
    end
  end
end
