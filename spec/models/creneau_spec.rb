describe Creneau, type: :model do
  let!(:motif) { create(:motif, name: "Vaccination", default_duration_in_min: 30) }
  let!(:lieu) { create(:lieu) }
  let(:today) { Date.new(2019, 9, 19)  }
  let(:six_days_later) { Date.new(2019, 9, 25) }
  let!(:plage_ouverture) { create(:plage_ouverture, :weekly, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }

  describe ".for_motif_and_lieu_from_date_range" do
    let(:motif_name) { motif.name }
    let(:next_7_days_range) { today..six_days_later }

    subject { Creneau.for_motif_and_lieu_from_date_range(motif_name, lieu, next_7_days_range) }

    it do
      expect(subject.size).to eq(4)

      expect_creneau_to_eq(subject[0], Time.zone.local(2019, 9, 19, 9, 0), 30, lieu.id, motif.id, plage_ouverture.id)
      expect_creneau_to_eq(subject[1], Time.zone.local(2019, 9, 19, 9, 30), 30, lieu.id, motif.id, plage_ouverture.id)
      expect_creneau_to_eq(subject[2], Time.zone.local(2019, 9, 19, 10, 0), 30, lieu.id, motif.id, plage_ouverture.id)
      expect_creneau_to_eq(subject[3], Time.zone.local(2019, 9, 19, 10, 30), 30, lieu.id, motif.id, plage_ouverture.id)
    end

    describe "with absence" do
      let!(:absence) { create(:absence, pro: plage_ouverture.pro, starts_at: Time.zone.local(2019, 9, 19, 9, 45), ends_at: Time.zone.local(2019, 9, 19, 10, 15)) }

      it do
        expect(subject.size).to eq(2)

        expect_creneau_to_eq(subject[0], Time.zone.local(2019, 9, 19, 9, 0), 30, lieu.id, motif.id, plage_ouverture.id)
        expect_creneau_to_eq(subject[1], Time.zone.local(2019, 9, 19, 10, 30), 30, lieu.id, motif.id, plage_ouverture.id)
      end
    end

    def expect_creneau_to_eq(creneau, starts_at, duration_in_min, lieu_id, motif_id, plage_ouverture_id)
      expect(creneau.starts_at).to eq(starts_at)
      expect(creneau.duration_in_min).to eq(duration_in_min)
      expect(creneau.lieu.id).to eq(lieu_id)
      expect(creneau.motif.id).to eq(motif_id)
      expect(creneau.plage_ouverture.id).to eq(plage_ouverture_id)
    end
  end

  describe "#available?" do
    # available?
    let(:creneau) { Creneau.new(starts_at: Time.zone.local(2019, 9, 19, 9, 0), duration_in_min: 60,lieu_id: lieu.id, motif_id: motif.id, plage_ouverture_id: plage_ouverture.id) }

    subject { creneau.available? }

    describe "absence overlap beginning of creneau" do
      let!(:absence) { create(:absence, starts_at: Time.zone.local(2019, 9, 19, 8, 30), ends_at: Time.zone.local(2019, 9, 19, 9, 30), pro: plage_ouverture.pro) }
      it { is_expected.to eq(false) }
    end

    describe "absence overlap end of creneau" do
      let!(:absence) { create(:absence, starts_at: Time.zone.local(2019, 9, 19, 9, 30), ends_at: Time.zone.local(2019, 9, 19, 10, 30), pro: plage_ouverture.pro) }
      it { is_expected.to eq(false) }
    end

    describe "absence is inside creneau" do
      let!(:absence) { create(:absence, starts_at: Time.zone.local(2019, 9, 19, 9, 15), ends_at: Time.zone.local(2019, 9, 19, 9, 30), pro: plage_ouverture.pro) }
      it { is_expected.to eq(false) }
    end

    describe "absence is before creneau" do
      let!(:absence) { create(:absence, starts_at: Time.zone.local(2019, 9, 19, 8, 0), ends_at: Time.zone.local(2019, 9, 19, 9, 00), pro: plage_ouverture.pro) }
      it { is_expected.to eq(true) }
    end

    describe "absence is after creneau" do
      let!(:absence) { create(:absence, starts_at: Time.zone.local(2019, 9, 19, 10, 00), ends_at: Time.zone.local(2019, 9, 19, 10, 30), pro: plage_ouverture.pro) }
      it { is_expected.to eq(true) }
    end

    describe "absence is around creneau" do
      let!(:absence) { create(:absence, starts_at: Time.zone.local(2019, 9, 19, 8, 00), ends_at: Time.zone.local(2019, 9, 19, 10, 30), pro: plage_ouverture.pro) }
      it { is_expected.to eq(false) }
    end

    describe "absence is like creneau" do
      let!(:absence) { create(:absence, starts_at: Time.zone.local(2019, 9, 19, 9, 00), ends_at: Time.zone.local(2019, 9, 19, 10, 00), pro: plage_ouverture.pro) }
      it { is_expected.to eq(false) }
    end
  end
end
