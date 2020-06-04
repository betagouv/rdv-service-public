describe MotifsHelper do
  describe "#motif_badges" do
    it "affiche le badge En ligne pour un motif `reservable_online`" do
      motif = build(:motif, reservable_online: true, location_type: :public_office)
      badges = motif_badges(motif)
      expect(badges).to include("En ligne")
      expect(badges).to include("badge-motif-reservable_online")
    end

    it "affiche le badge À domicile pour un motif `home`" do
      motif = build(:motif, reservable_online: false, location_type: :home)
      badges = motif_badges(motif)
      expect(badges).to include("À domicile")
      expect(badges).to include("badge-motif-home")
    end

    it "affiche rien pour un motif `public_office`" do
      motif = build(:motif, reservable_online: false, location_type: :public_office)
      badges = motif_badges(motif)
      expect(badges).to eq("")
    end

    it "affiche le badge Par tél.  pour un motif `phone`" do
      motif = build(:motif, reservable_online: false, location_type: :phone)
      badges = motif_badges(motif)
      expect(badges).to include("Par tél.")
      expect(badges).to include("badge-motif-phone")
    end

    it "affiche le badge Secrétariat pour un motif `secretariat`" do
      motif = build(:motif, reservable_online: false, location_type: :public_office, for_secretariat: true)
      badges = motif_badges(motif)
      expect(badges).to include("Secrétariat")
      expect(badges).to include("badge-motif-secretariat")
    end

    it "affiche le badge Suivi pour un motif `follow_up`" do
      motif = build(:motif, reservable_online: false, location_type: :public_office, follow_up: true)
      badges = motif_badges(motif)
      expect(badges).to include("Suivi")
      expect(badges).to include("badge-motif-follow_up")
    end

    it "affiche le badge Suivi ET Par tél. pour un motif `home` et `follow_up`" do
      motif = build(:motif, reservable_online: false, location_type: :phone, follow_up: true)
      badges = motif_badges(motif)
      expect(badges).to include("Suivi")
      expect(badges).to include("badge-motif-follow_up")
      expect(badges).to include("Par tél.")
      expect(badges).to include("badge-motif-phone")
    end
  end
end
