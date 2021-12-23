# frozen_string_literal: true

describe FullNameConcern do
  let(:marie) { build :user, first_name: "Marie", last_name: "Curie", birth_name: "Skłodowska" }
  let(:pierre) { build :user, first_name: "Pierre", last_name: "Curie", birth_name: "" }

  describe "#full_name" do
    subject { person.full_name }

    context "with birth_name" do
      let(:person) { marie }

      it { is_expected.to eq "Marie CURIE (Skłodowska)" }
    end

    context "without birth_name" do
      let(:person) { pierre }

      it { is_expected.to eq "Pierre CURIE" }
    end
  end

  describe "reverse_full_name" do
    subject { person.reverse_full_name }

    context "with birth_name" do
      let(:person) { marie }

      it { is_expected.to eq "CURIE (Skłodowska) Marie" }
    end

    context "without birth_name" do
      let(:person) { pierre }

      it { is_expected.to eq "CURIE Pierre" }
    end
  end

  describe "short_name" do
    subject { person.short_name }

    context "with birth_name" do
      let(:person) { marie }

      it { is_expected.to eq "M. CURIE" }
    end

    context "without birth_name" do
      let(:person) { pierre }

      it { is_expected.to eq "P. CURIE" }
    end
  end
end
