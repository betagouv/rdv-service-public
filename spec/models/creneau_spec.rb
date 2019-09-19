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

      expect(subject[0].starts_at).to eq(Time.zone.local(2019, 9, 19, 9, 0))
      expect(subject[0].duration_in_min).to eq(30)
      expect(subject[0].lieu_id).to eq(lieu.id)
      expect(subject[0].motif_id).to eq(motif.id)
      expect(subject[0].plage_ouverture_id).to eq(plage_ouverture.id)

      expect(subject[1].starts_at).to eq(Time.zone.local(2019, 9, 19, 9, 30))
      expect(subject[1].duration_in_min).to eq(30)
      expect(subject[1].lieu_id).to eq(lieu.id)
      expect(subject[1].motif_id).to eq(motif.id)
      expect(subject[1].plage_ouverture_id).to eq(plage_ouverture.id)

      expect(subject[2].starts_at).to eq(Time.zone.local(2019, 9, 19, 10, 0))
      expect(subject[2].duration_in_min).to eq(30)
      expect(subject[2].lieu_id).to eq(lieu.id)
      expect(subject[2].motif_id).to eq(motif.id)
      expect(subject[2].plage_ouverture_id).to eq(plage_ouverture.id)

      expect(subject[3].starts_at).to eq(Time.zone.local(2019, 9, 19, 10, 30))
      expect(subject[3].duration_in_min).to eq(30)
      expect(subject[3].lieu_id).to eq(lieu.id)
      expect(subject[3].motif_id).to eq(motif.id)
      expect(subject[3].plage_ouverture_id).to eq(plage_ouverture.id)
    end
  end
end
