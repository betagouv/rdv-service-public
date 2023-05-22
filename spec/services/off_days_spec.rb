# frozen_string_literal: true

describe OffDays, type: :service do
  it "is up to date" do
    # Il faut ajouter de nouveaux jours fériés si cette spec échoue
    expect(described_class::JOURS_FERIES.to_a.last).to be > 3.months.from_now
  end

  describe ".all_in_date_range" do
    subject { described_class.all_in_date_range(range) }

    context "when jour ferie is the first day of the range" do
      let(:range) { Date.new(2023, 1, 1)..Date.new(2023, 1, 7) }

      it { is_expected.to match_array([Date.new(2023, 1, 1)]) }
    end

    context "when jour ferie is the last day of the range" do
      let(:range) { Date.new(2019, 12, 20)..Date.new(2023, 1, 1) }

      it { is_expected.to match_array([Date.new(2023, 1, 1)]) }
    end

    context "when date range is only one day" do
      let(:range) { Date.new(2023, 1, 1)..Date.new(2023, 1, 1) }

      it { is_expected.to match_array([Date.new(2023, 1, 1)]) }
    end

    context "it works with datetime" do
      let(:range) { Time.zone.parse("20230101 16:00")..Time.zone.parse("20230107 18:00") }

      it { is_expected.to match_array([Date.new(2023, 1, 1)]) }
    end

    context "with a nil date_range given" do
      it "returns empty array" do
        expect(described_class.all_in_date_range(nil)).to be_empty
      end
    end
  end
end
