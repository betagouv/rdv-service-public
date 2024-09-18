RSpec.describe Absence, type: :model do
  it_behaves_like "recurrence"

  describe "title mandatory" do
    it "valide wit a title" do
      expect(build(:absence, title: "Indisponibilité")).to be_valid
    end

    it "invalide without title" do
      expect(build(:absence, title: nil)).to be_invalid
    end
  end

  describe "no reccurence for absence for several days" do
    it "invalid with recurrence and absence on more than one day" do
      expect(build(:absence, :weekly, first_day: Date.new(2019, 7, 20), end_day: Date.new(2019, 7, 23))).to be_invalid
    end

    it "valid without recurrence and absence on more than one day" do
      expect(build(:absence, first_day: Date.new(2019, 7, 20), end_day: Date.new(2019, 7, 23))).to be_valid
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

  describe "expired?" do
    # cas particulier de l'absence qui a une date de fin à prendre ne compte
    it "return false when end_day after today" do
      today = Time.zone.parse("20210323 13:45")
      travel_to(today)
      absence = build(:absence, first_day: today - 3.days, end_day: today + 3.days)
      expect(absence.expired?).to be false
    end

    it "return true when end_day before today" do
      today = Time.zone.parse("20210323 13:45")
      travel_to(today)
      absence = build(:absence, first_day: today - 3.days, end_day: today - 1.day, recurrence: nil)
      expect(absence.expired?).to be true
    end

    it "return true when first_day before today without end_day" do
      today = Time.zone.parse("20210323 13:45")
      travel_to(today)
      absence = build(:absence, first_day: today - 3.days, end_day: today - 3.days)
      expect(absence.expired?).to be true
    end

    it "return stil works for plage_ouverture" do
      today = Time.zone.parse("20210323 13:45")
      travel_to(today)
      plage_ouverture = build(:plage_ouverture, first_day: today - 3.days)
      expect(plage_ouverture.expired?).to be true
    end
  end

  describe "first day realistic validations" do
    context "first day before 2018" do
      let(:absence) { build(:absence, first_day: Date.new(2017, 12, 24)) }

      it "should be invalid" do
        expect(absence).to be_invalid
        expect(absence.errors.full_messages.first).to eq("La date de début ne peut pas être avant 2018")
      end
    end

    context "first day more than 5 years from now" do
      let(:absence) { build(:absence, first_day: Date.new(2100, 12, 24)) }

      it "should be invalid" do
        expect(absence).to be_invalid
        expect(absence.errors.full_messages.first).to eq("La date de début ne peut pas être dans plus de 5 ans")
      end
    end

    context "first day is reasonable" do
      let(:absence) { build(:absence, first_day: Date.new(2020, 12, 24)) }

      it "should be valid" do
        expect(absence).to be_valid
      end
    end
  end

  describe "end_day realistic validations" do
    context "end_day before 2018" do
      let(:absence) { build(:absence, first_day: Date.new(2015, 12, 24), end_day: Date.new(2017, 12, 24)) }

      it "should be invalid" do
        expect(absence).to be_invalid
        expect(absence.errors.full_messages).to include("La date de fin ne peut pas être avant 2018")
      end
    end

    context "end_day more than 5 years from now" do
      let(:absence) { build(:absence, first_day: Date.new(2020, 12, 1), end_day: Date.new(2100, 12, 24)) }

      it "should be invalid" do
        expect(absence).to be_invalid
        expect(absence.errors.full_messages).to include("La date de fin ne peut pas être dans plus de 5 ans")
      end
    end

    context "end_day is reasonable" do
      let(:absence) { build(:absence, first_day: Date.new(2020, 12, 1), end_day: Date.new(2020, 12, 24)) }

      it "should be valid" do
        expect(absence).to be_valid
      end
    end
  end
end
