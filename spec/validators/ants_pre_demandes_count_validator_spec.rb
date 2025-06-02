require "rails_helper"

RSpec.describe AntsPreDemandesCountValidator do
  describe ".count_valid?" do
    subject { described_class.count_valid?(value) }

    context "when the value is 1" do
      let(:value) { 1 }

      it { is_expected.to be true }
    end

    [-1, 0, 7, 10].each do |invalid_value|
      context "when the value is #{invalid_value}" do
        let(:value) { invalid_value }

        it { is_expected.to be false }
      end
    end

    context "when the value is blank" do
      let(:value) { nil }

      it { is_expected.to be true }
    end

    context "when the value is not a number" do
      let(:value) { "abc" }

      it { is_expected.to be false }
    end
  end
end
