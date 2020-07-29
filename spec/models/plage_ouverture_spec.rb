describe PlageOuverture, type: :model do
  describe '#end_after_start' do
    let(:plage_ouverture) { build(:plage_ouverture, start_time: start_time, end_time: end_time) }

    context 'start_time < end_time' do
      let(:start_time) { Tod::TimeOfDay.new(7) }
      let(:end_time) { Tod::TimeOfDay.new(8) }

      it { expect(plage_ouverture.send(:end_after_start)).to be_nil }
    end

    context 'start_time = end_time' do
      let(:start_time) { Tod::TimeOfDay.new(7) }
      let(:end_time) { start_time }

      it { expect(plage_ouverture.send(:end_after_start)).to eq(["doit être après l'heure de début"]) }
    end

    context 'start_time > end_time' do
      let(:start_time) { Tod::TimeOfDay.new(7, 30) }
      let(:end_time) { Tod::TimeOfDay.new(7) }

      it { expect(plage_ouverture.send(:end_after_start)).to eq(["doit être après l'heure de début"]) }
    end
  end

  require Rails.root.join 'spec/models/concerns/recurrence_concern_spec.rb'
  it_behaves_like 'recurrence'

  describe '.for_motif_and_lieu_from_date_range' do
    let!(:motif) { create(:motif, name: 'Vaccination', default_duration_in_min: 30) }
    let!(:lieu) { create(:lieu) }
    let(:today) { Date.new(2019, 9, 19) }
    let(:six_days_later) { Date.new(2019, 9, 25) }
    let!(:plage_ouverture) { create(:plage_ouverture, :weekly, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }
    let(:agent_ids) { nil }

    subject { PlageOuverture.for_motif_and_lieu_from_date_range(motif.name, lieu, today..six_days_later, agent_ids) }

    it { expect(subject).to contain_exactly(plage_ouverture) }

    describe 'when first_day is the last day of time range' do
      let!(:plage_ouverture) { create(:plage_ouverture, :weekly, motifs: [motif], lieu: lieu, first_day: six_days_later, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }

      it { expect(subject).to contain_exactly(plage_ouverture) }
    end

    describe 'when first_day is before time range' do
      let!(:plage_ouverture) { create(:plage_ouverture, :weekly, motifs: [motif], lieu: lieu, first_day: today - 2.days, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }

      it { expect(subject).to contain_exactly(plage_ouverture) }
    end

    describe 'when first_day is after time range' do
      let!(:plage_ouverture) { create(:plage_ouverture, :weekly, motifs: [motif], lieu: lieu, first_day: today + 8.days, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }

      it { expect(subject.count).to eq(0) }
    end

    describe 'when agent_ids is passed to filter' do
      let(:agent_ids) { [plage_ouverture.agent_id] }

      it { expect(subject).to contain_exactly(plage_ouverture) }

      describe 'and plage_ouverture.agent_id is not passed' do
        let(:agent_ids) { [create(:agent).id, create(:agent).id] }

        it { expect(subject.count).to eq(0) }
      end

      describe 'and there is another plage_ouverture' do
        let!(:plage_ouverture2) { create(:plage_ouverture, :weekly, motifs: [motif], lieu: lieu, first_day: today, agent: create(:agent), start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11)) }

        it { expect(subject).to contain_exactly(plage_ouverture) }
      end
    end
  end

  describe '#expired?' do
    subject { plage_ouverture.expired? }

    context 'with exceptionnelles plages' do
      describe 'when first_day is in past' do
        let(:plage_ouverture) { create(:plage_ouverture, :no_recurrence, first_day: 2.days.ago) }

        it { should be true }
      end

      describe 'when first_day is in future' do
        let(:plage_ouverture) { create(:plage_ouverture, :no_recurrence, first_day: 2.days.from_now) }

        it { should be false }
      end

      describe 'when first_day is today' do
        let(:plage_ouverture) { create(:plage_ouverture, :no_recurrence, first_day: Date.today) }

        it { should be false }
      end
    end

    context 'with plages regulières' do
      describe 'when until is in past' do
        let(:plage_ouverture) { create(:plage_ouverture, recurrence: Montrose.every(:week, until: 2.days.ago).to_json) }

        it { should be true }
      end

      describe 'when until is in future' do
        let(:plage_ouverture) { create(:plage_ouverture, recurrence: Montrose.every(:week, until: 2.days.from_now).to_json) }

        it { should be false }
      end

      describe 'when until is today' do
        let(:plage_ouverture) { create(:plage_ouverture, recurrence: Montrose.every(:week, until: Date.today).to_json) }

        it { should be false }
      end
    end
  end

  describe '#available_motifs' do
    let!(:motif) { create(:motif) }
    let!(:motif2) { create(:motif) }
    let!(:motif3) { create(:motif, :for_secretariat) }
    let!(:motif4) { create(:motif, organisation: create(:organisation)) }
    let(:plage_ouverture) { build(:plage_ouverture, agent: agent) }

    subject { plage_ouverture.available_motifs }

    describe 'for secretaire' do
      let(:agent) { create(:agent, :secretaire) }

      it { is_expected.to contain_exactly(motif3) }
    end

    describe 'for other service' do
      let(:agent) { create(:agent, service: motif.service) }

      it { is_expected.to contain_exactly(motif, motif2, motif3) }
    end
  end

  describe '#plage_ouverture_created' do
    let(:plage_ouverture) { build(:plage_ouverture) }

    it 'should be called after create' do
      expect(plage_ouverture).to receive(:plage_ouverture_created)
      plage_ouverture.save!
    end

    context 'when rdv already exist' do
      let(:plage_ouverture) { create(:plage_ouverture) }

      it 'should not be called' do
        expect(plage_ouverture).not_to receive(:plage_ouverture_created)
        plage_ouverture.save!
      end
    end

    it 'calls Agents::PlageOuvertureMailer to send email to agetn' do
      expect(Agents::PlageOuvertureMailer).to receive(:plage_ouverture_created).with(plage_ouverture).and_return(double(deliver_later: nil))
      plage_ouverture.save!
    end
  end
end
