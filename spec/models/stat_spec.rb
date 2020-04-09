describe Stat, type: :model do
  describe "#rdvs_group_by_type" do
    it "return empty hash without rdv" do
      stats = Stat.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type).to eq({})
    end

    it "return 2=>1 with one home rdv" do
      home_motif = create(:motif, location_type: :home)
      create(:rdv, motif: home_motif)
      stats = Stat.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type).to eq({ "à domicile" => 1 })
    end

    it "return 2=>2 with two home rdv" do
      home_motif = create(:motif, location_type: :home)
      create(:rdv, motif: home_motif)
      create(:rdv, motif: home_motif)
      stats = Stat.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type).to eq({ "à domicile" => 2 })
    end

    it "return 2=>2 with two different motif of home rdv" do
      home_motif = create(:motif, location_type: :home)
      other_home_motif = create(:motif, location_type: :home)
      create(:rdv, motif: home_motif)
      create(:rdv, motif: other_home_motif)
      stats = Stat.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type).to eq({ "à domicile" => 2 })
    end

    it "return {2=>1, 1=>1} with one home rdv and one phone" do
      home_motif = create(:motif, location_type: :home)
      phone_motif = create(:motif, location_type: :phone)
      create(:rdv, motif: home_motif)
      create(:rdv, motif: phone_motif)
      stats = Stat.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type).to eq({ "par téléphone" => 1, "à domicile" => 1 })
    end

    it "return {2=>1, 1=>1, 0=>1 with each available motif" do
      home_motif = create(:motif, location_type: :home)
      phone_motif = create(:motif, location_type: :phone)
      public_office_motif = create(:motif, location_type: :public_office)
      create(:rdv, motif: home_motif)
      create(:rdv, motif: phone_motif)
      create(:rdv, motif: public_office_motif)
      stats = Stat.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type).to eq({ "par téléphone" => 1, "à domicile" => 1, "au local" => 1 })
    end
  end
end
