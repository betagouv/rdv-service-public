# frozen_string_literal: true

describe Absence, type: :model do
  it_behaves_like "recurrence"

  describe "title mandatory" do
    it "valide wit a title" do
      expect(build(:absence, title: "Indisponibilité")).to be_valid
    end

    it "invalide without title" do
      expect(build(:absence, title: nil)).to be_invalid
    end
  end

  describe "#occurrences_for" do
    subject { absence.occurrences_for(date_range) }

    context "if the absence lasts many days" do
      let(:absence) { build(:absence, :no_recurrence, first_day: (date_range.end - 30.days), end_day: date_range.end) }
      let(:date_range) { Date.new(2019, 7, 22)..Date.new(2019, 7, 28) }

      it do
        expect(subject.size).to eq 1
        expect(subject.first.starts_at).to eq absence.starts_at
        expect(subject.first.ends_at).to eq absence.first_occurrence_ends_at
      end

      context "if the abence has many occurrences in range" do
        let(:absence) { build(:absence, :weekly, first_day: Date.new(2019, 7, 20), end_day: Date.new(2019, 7, 23)) }
        let(:date_range) { Date.new(2019, 7, 29)..Date.new(2019, 8, 4) }

        it do
          expect(subject.size).to eq 2
          expect(subject.first.starts_at).to eq(absence.starts_at + 1.week) # first one ends in range
          expect(subject.first.ends_at).to eq(absence.first_occurrence_ends_at + 1.week) # first one ends in range
          expect(subject.second.starts_at).to eq(absence.starts_at + 2.weeks) # second one starts in range
          expect(subject.second.ends_at).to eq(absence.first_occurrence_ends_at + 2.weeks) # second one starts in range
        end
      end
    end
  end
end
