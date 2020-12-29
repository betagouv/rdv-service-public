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

  describe "#text_color" do
    it "return white when blank given" do
      expect(text_color(nil)).to eq("white")
      expect(text_color("")).to eq("white")
    end

    it "return black when white given" do
      expect(text_color("#FFFFFF")).to eq("#000000")
    end

    it "return white when a red given" do
      expect(text_color("#F04049")).to eq("#FFFFFF")
    end

    it "return black when a orange given" do
      expect(text_color("#FAA23F")).to eq("#000000")
    end

    it "return black when a yellow given" do
      expect(text_color("#FDF04E")).to eq("#000000")
    end

    it "return black when a green given" do
      expect(text_color("#80C357")).to eq("#000000")
    end

    it "return white when a other green given" do
      expect(text_color("#17A079")).to eq("#FFFFFF")
    end

    it "return white when a other light blue given" do
      expect(text_color("#88C8EA")).to eq("#000000")
    end

    it "return white when a other marine blue given" do
      expect(text_color("#394C9A")).to eq("#FFFFFF")
    end

    it "return white when a other purple given" do
      expect(text_color("#D64695")).to eq("#FFFFFF")
    end
  end
end
