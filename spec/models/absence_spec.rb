describe Absence, type: :model do
  require Rails.root.join "spec/models/concerns/recurrence_concern_spec.rb"
  it_behaves_like "recurrence"

  describe "#occurences_for" do
    subject { absence.occurences_for(date_range) }

    context "if the absence lasts many days" do
      let(:absence) { build(:absence, :no_recurrence, first_day: (date_range.end - 30.day), end_day: date_range.end) }
      let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 7, 28) }

      it do
        expect(subject.size).to eq 1
        expect(subject.first.starts_at).to eq absence.starts_at
        expect(subject.first.ends_at).to eq absence.ends_at
      end

      context "if the abence has many occurrences in range" do
        let(:absence) { build(:absence, :weekly, first_day: Date.new(2019, 7, 20), end_day: Date.new(2019, 7, 23)) }
        let(:date_range) { Date.new(2019, 7, 29)..Date.new(2019, 8, 4) }

        it do
          expect(subject.size).to eq 2
          expect(subject.first.starts_at).to eq(absence.starts_at + 1.weeks) # first one ends in range
          expect(subject.first.ends_at).to eq(absence.ends_at + 1.weeks) # first one ends in range
          expect(subject.second.starts_at).to eq(absence.starts_at + 2.weeks) # second one starts in range
          expect(subject.second.ends_at).to eq(absence.ends_at + 2.weeks) # second one starts in range
        end
      end
    end
  end
end
