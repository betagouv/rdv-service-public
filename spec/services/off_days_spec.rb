# frozen_string_literal: true

describe OffDays, type: :service do
  describe ".all_in_date_range" do
    subject { described_class.all_in_date_range(range) }

    context "when jour ferie is the first day of the range" do
      let(:range) { Date.new(2020, 1, 1)..Date.new(2020, 1, 7) }

      it { is_expected.to match_array([Date.new(2020, 1, 1)]) }
    end

    context "when jour ferie is the last day of the range" do
      let(:range) { Date.new(2019, 12, 20)..Date.new(2020, 1, 1) }

      it { is_expected.to match_array([Date.new(2020, 1, 1)]) }
    end

    context "when there is a lot of jours feries" do
      let(:range) { Date.new(2020, 5, 1)..Date.new(2020, 5, 31) }

      it { is_expected.to match_array([Date.new(2020, 5, 1), Date.new(2020, 5, 8), Date.new(2020, 5, 21)]) }
    end

    context "when there is a lot of jours feries in 2021" do
      let(:range) { Date.new(2021, 5, 1)..Date.new(2021, 5, 31) }

      it { is_expected.to match_array([Date.new(2021, 5, 1), Date.new(2021, 5, 8), Date.new(2021, 5, 13), Date.new(2021, 5, 24)]) }
    end

    context "when date range is only one day" do
      let(:range) { Date.new(2020, 1, 1)..Date.new(2020, 1, 1) }

      it { is_expected.to match_array([Date.new(2020, 1, 1)]) }
    end

    context "this test should be green on 1st Jan 2021, meanwhile do not run it" do
      let(:range) { Date.new(2022, 1, 1)..Date.new(2022, 1, 7) }

      it { is_expected.to match_array([Date.new(2022, 1, 1)]) } if Time.zone.now > Date.new(2021, 1, 1)
    end

    context "it works with datetime" do
      let(:range) { Time.zone.parse("20220101 16:00")..Time.zone.parse("20220107 18:00") }

      it { is_expected.to match_array([Date.new(2022, 1, 1)]) } if Time.zone.now > Date.new(2021, 1, 1)
    end

    context "with a nil date_range given" do
      it "returns empty array" do
        expect(described_class.all_in_date_range(nil)).to be_empty
      end
    end
  end
end
