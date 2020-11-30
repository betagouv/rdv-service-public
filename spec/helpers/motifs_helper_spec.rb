describe MotifsHelper do
  describe "#motif_badges" do
    it "affiche le badge Secrétariat pour un motif `secretariat`" do
      motif = build(:motif, reservable_online: false, for_secretariat: true)
      badges = motif_badges(motif)
      expect(badges).to include("Secrétariat")
      expect(badges).to include("badge-motif-secretariat")
    end

    it "affiche le badge Suivi pour un motif `follow_up`" do
      motif = build(:motif, reservable_online: false, follow_up: true)
      badges = motif_badges(motif)
      expect(badges).to include("Suivi")
      expect(badges).to include("badge-motif-follow_up")
    end

    it "affiche le badge secretariat ET followup pour un motif `for_secretariat` et `follow_up`" do
      motif = build(:motif, reservable_online: false, follow_up: true, for_secretariat: true)
      badges = motif_badges(motif)
      expect(badges).to include("Secrétariat")
      expect(badges).to include("badge-motif-secretariat")
      expect(badges).to include("Suivi")
      expect(badges).to include("badge-motif-follow_up")
    end
  end
end
