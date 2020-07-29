describe Stat, type: :model do
  describe '#rdvs_group_by_type' do
    it 'return empty hash without rdv' do
      stats = Stat.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type).to eq({})
    end

    it 'return 2=>1 with one home rdv' do
      home_motif = create(:motif, location_type: :home)
      create(:rdv, motif: home_motif, created_at: DateTime.new(2020, 4, 7, 10, 0))
      stats = Stat.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[['à domicile', '05/04/2020']]).to eq(1)
    end

    it 'return 2=>2 with two home rdv' do
      home_motif = create(:motif, location_type: :home)
      2.times { create(:rdv, motif: home_motif, created_at: DateTime.new(2020, 4, 7, 10, 0)) }
      stats = Stat.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[['à domicile', '05/04/2020']]).to eq(2)
    end

    it 'return 2=>2 with two different motif of home rdv' do
      home_motif = create(:motif, location_type: :home)
      other_home_motif = create(:motif, location_type: :home)
      create(:rdv, motif: home_motif, created_at: DateTime.new(2020, 4, 7, 10, 0))
      create(:rdv, motif: other_home_motif, created_at: DateTime.new(2020, 4, 7, 10, 0))
      stats = Stat.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[['à domicile', '05/04/2020']]).to eq(2)
    end

    it 'return {2=>1, 1=>1} with one home rdv and one phone' do
      home_motif = create(:motif, location_type: :home)
      phone_motif = create(:motif, location_type: :phone)
      create(:rdv, motif: home_motif, created_at: DateTime.new(2020, 4, 7, 10, 0))
      create(:rdv, motif: phone_motif, created_at: DateTime.new(2020, 4, 7, 11, 0))
      stats = Stat.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[['à domicile', '05/04/2020']]).to eq(1)
      expect(stats.rdvs_group_by_type[['par téléphone', '05/04/2020']]).to eq(1)
    end

    it 'return {2=>1, 1=>1, 0=>1 with each available motif' do
      home_motif = create(:motif, location_type: :home)
      phone_motif = create(:motif, location_type: :phone)
      public_office_motif = create(:motif, location_type: :public_office)
      create(:rdv, motif: home_motif, created_at: DateTime.new(2020, 4, 7, 10, 0))
      create(:rdv, motif: phone_motif, created_at: DateTime.new(2020, 4, 7, 11, 0))
      create(:rdv, motif: public_office_motif, created_at: DateTime.new(2020, 4, 7, 9, 40))
      stats = Stat.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[['à domicile', '05/04/2020']]).to eq(1)
      expect(stats.rdvs_group_by_type[['par téléphone', '05/04/2020']]).to eq(1)
      expect(stats.rdvs_group_by_type[['sur place', '05/04/2020']]).to eq(1)
    end
  end
end
