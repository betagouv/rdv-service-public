# frozen_string_literal: true

describe SearchRdvCollectif, type: :service do
  describe "#next_availability_for_lieu" do
    let(:organisation) { create(:organisation) }

    it "returns nil availability without RDV Collectif" do
      lieu = create(:lieu, organisation: organisation)
      motif = create(:motif, organisation: organisation, collectif: false)
      expect(described_class.next_availability_for_lieu(motif, lieu).next_availability).to be_nil
    end

    it "returns the given lieu" do
      lieu = create(:lieu, organisation: organisation)
      motif = create(:motif, organisation: organisation, collectif: true)
      expect(described_class.next_availability_for_lieu(motif, lieu).lieu).to eq(lieu)
    end

    it "returns next_availabilty for lieu" do
      now = Time.zone.parse("2022-08-09 11h00")
      travel_to(now)

      next_availability = now + 3.days
      lieu = create(:lieu, organisation: organisation)
      motif = create(:motif, organisation: organisation, collectif: true, reservable_online: true)
      next_rdv = create(:rdv, lieu: lieu, motif: motif, starts_at: next_availability, organisation: organisation)
      create(:rdv, lieu: lieu, motif: motif, starts_at: next_availability + 1.hour, organisation: organisation)

      expect(described_class.next_availability_for_lieu(motif, lieu).next_availability).to eq(next_rdv)
    end
  end

  describe "#starts_at_for_first" do
    it "returns nil when RDVs empty" do
      expect(described_class.starts_at_for_first([])).to be_nil
    end

    it "returns first RDV start_at" do
      now = Time.zone.parse("2022-08-09 9h00")
      travel_to(now)
      first_starts_at = now + 1.day
      first_rdv = create(:rdv, starts_at: first_starts_at)
      rdv = create(:rdv, starts_at: now + 2.days)
      expect(described_class.starts_at_for_first([first_rdv, rdv])).to eq(first_starts_at)
    end
  end

  describe "#rdvs_collectif_at" do
    let(:lieu) { create(:lieu) }

    it "returns empty array without RDV" do
      motif = create(:motif, :collectif)
      expect(described_class.rdvs_collectif_at(motif, lieu)).to be_empty
    end

    it "returns all RDV of this lieu" do
      motif = create(:motif, :collectif)
      rdv = create(:rdv, lieu: lieu, motif: motif)
      create(:rdv, lieu: create(:lieu))
      expect(described_class.rdvs_collectif_at(motif, lieu)).to eq([rdv])
    end

    it "returns only collective RDV" do
      motif = create(:motif, collectif: true)
      rdv = create(:rdv, lieu: lieu, motif: motif)

      individual_motif = create(:motif, collectif: false)
      create(:rdv, lieu: lieu, motif: individual_motif)
      expect(described_class.rdvs_collectif_at(motif, lieu)).to eq([rdv])
    end

    it "returns only future RDV" do
      now = Time.zone.parse("2022-08-09 11h00")

      motif = create(:motif, collectif: true)
      rdv = create(:rdv, lieu: lieu, motif: motif)

      travel_to(now - 1.week) # bypass RDV validation on past RDV creation
      create(:rdv, lieu: lieu, motif: motif, starts_at: now - 1.week)

      travel_to(now)
      expect(described_class.rdvs_collectif_at(motif, lieu)).to eq([rdv])
    end

    it "returns only open to public RDV" do
      open_to_public_motif = create(:motif, collectif: true, reservable_online: true)
      rdv = create(:rdv, lieu: lieu, motif: open_to_public_motif)
      motif = rdv.motif
      close_to_public_motif = create(:motif, collectif: true, reservable_online: false)
      create(:rdv, lieu: lieu, motif: close_to_public_motif)

      expect(described_class.rdvs_collectif_at(motif, lieu)).to eq([rdv])
    end

    it "returns RDV sorted by starts at desc" do
      now = Time.zone.parse("2022-08-09 11h00")
      travel_to(now)

      motif = create(:motif, collectif: true, reservable_online: true)
      next_rdv = create(:rdv, lieu: lieu, motif: motif, starts_at: now + 3.days)
      rdv = create(:rdv, lieu: lieu, motif: motif, starts_at: now + 2.days)

      expect(described_class.rdvs_collectif_at(motif, lieu)).to eq([rdv, next_rdv])
    end

    it "returns only RDV with remaining seats" do
      motif = create(:motif, collectif: true, reservable_online: true)

      rdv = create(:rdv, lieu: lieu, motif: motif, max_participants_count: 2, users: [])
      create(:rdv, lieu: lieu, motif: motif, max_participants_count: 2, users: create_list(:user, 2))

      expect(described_class.rdvs_collectif_at(motif, lieu)).to eq([rdv])
    end

    it "returns only RDV for given motif" do
      motif = create(:motif, collectif: true, reservable_online: true)
      other_motif = create(:motif, collectif: true, reservable_online: true)

      rdv = create(:rdv, lieu: lieu, motif: motif, max_participants_count: 2, users: [])
      create(:rdv, lieu: lieu, motif: other_motif, max_participants_count: 2, users: [])

      expect(described_class.rdvs_collectif_at(motif, lieu)).to eq([rdv])
    end

    it "returns only RDV where I am not already registered" do
      user = create(:user)
      motif = create(:motif, collectif: true, reservable_online: true)

      rdv = create(:rdv, lieu: lieu, motif: motif, max_participants_count: 2, users: [])
      create(:rdv, lieu: lieu, motif: motif, max_participants_count: 2, users: [user])

      expect(described_class.rdvs_collectif_at(motif, lieu, user)).to eq([rdv])
    end
  end

  describe "#available_slots" do
    it "returns empty without available collective RDV" do
      lieu = create(:lieu)
      motif = create(:motif, collectif: true, reservable_online: true)
      expect(described_class.available_slots(motif, lieu)).to be_empty
    end

    it "returns future collective RDV" do
      now = Time.zone.parse("2022-08-09 11h00")
      travel_to(now)

      lieu = create(:lieu)
      motif = create(:motif, collectif: true, reservable_online: true)
      create(:rdv, lieu: lieu, motif: create(:motif, collectif: false), starts_at: now - 1.day)
      create(:rdv, lieu: lieu, motif: motif, starts_at: now - 1.day)
      rdv = create(:rdv, lieu: lieu, motif: motif, starts_at: now + 2.days)
      expect(described_class.available_slots(motif, lieu)).to eq([rdv])
    end

    it "returns collective RDV with remaining seats" do
      lieu = create(:lieu)
      motif = create(:motif, collectif: true, reservable_online: true)

      rdv = create(:rdv, lieu: lieu, motif: motif, max_participants_count: 2, users: [])
      create(:rdv, lieu: lieu, motif: motif, max_participants_count: 2, users: create_list(:user, 2))

      expect(described_class.available_slots(motif, lieu)).to eq([rdv])
    end

    it "returns collective RDV for given motif" do
      lieu = create(:lieu)
      motif = create(:motif, collectif: true, reservable_online: true)
      autre_motif = create(:motif, collectif: true, reservable_online: true)

      rdv = create(:rdv, lieu: lieu, motif: motif)
      create(:rdv, lieu: lieu, motif: autre_motif)

      expect(described_class.available_slots(motif, lieu)).to eq([rdv])
    end

    it "returns collective RDV at given lieu" do
      lieu = create(:lieu)
      autre_lieu = create(:lieu)
      motif = create(:motif, collectif: true, reservable_online: true)

      rdv = create(:rdv, lieu: lieu, motif: motif)
      create(:rdv, lieu: autre_lieu, motif: motif)

      expect(described_class.available_slots(motif, lieu)).to eq([rdv])
    end
  end
end
