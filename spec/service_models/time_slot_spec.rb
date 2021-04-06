describe TimeSlot, type: :service do
  describe "initialize" do
    it "works with valid times" do
      expect { described_class.new(Time.new(2020, 12, 2, 10, 30), Time.new(2020, 12, 2, 11, 30)) }.not_to raise_error
    end

    it "raises with non consecutive times" do
      expect { described_class.new(Time.new(2020, 12, 2, 12, 30), Time.new(2020, 12, 2, 11, 30)) }.to raise_error(TimeSlot::OutOfOrderTimesError)
    end

    it "raises with different dates" do
      expect { described_class.new(Time.new(2020, 12, 2, 10, 30), Time.new(2020, 12, 3, 11, 30)) }.to raise_error(TimeSlot::DifferentDatesError)
    end
  end

  describe "#intersects?" do
    subject { slot1.intersects?(slot2) }

    shared_examples "intersects" do
      it { expect(slot1.intersects?(slot2)).to eq true }
      it { expect(slot2.intersects?(slot1)).to eq true }
    end

    shared_examples "does not intersect" do
      it { expect(slot1.intersects?(slot2)).to eq false }
      it { expect(slot2.intersects?(slot1)).to eq false }
    end

    context "slot1 is before slot2" do
      let(:slot1) { described_class.new(Time.new(2020, 12, 2, 9), Time.new(2020, 12, 2, 10)) }
      let(:slot2) { described_class.new(Time.new(2020, 12, 2, 10, 30), Time.new(2020, 12, 2, 11, 30)) }
      # slot1    |-----|
      # slot2              |-----|

      it_behaves_like "does not intersect"
    end

    context "slot1 overlaps partially from beginning" do
      # slot1    |-----|
      # slot2        |-----|
      let(:slot1) { described_class.new(Time.new(2020, 12, 2, 9), Time.new(2020, 12, 2, 11)) }
      let(:slot2) { described_class.new(Time.new(2020, 12, 2, 10, 30), Time.new(2020, 12, 2, 11, 30)) }

      it_behaves_like "intersects"
    end

    context "slot1 is included in slot2" do
      # slot1    |-----|
      # slot2  |---------|
      let(:slot1) { described_class.new(Time.new(2020, 12, 2, 10, 45), Time.new(2020, 12, 2, 11)) }
      let(:slot2) { described_class.new(Time.new(2020, 12, 2, 10, 30), Time.new(2020, 12, 2, 11, 30)) }

      it_behaves_like "intersects"
    end

    context "slot1 overlaps partially from middle" do
      # slot1        |-----|
      # slot2    |-----|
      let(:slot1) { described_class.new(Time.new(2020, 12, 2, 11), Time.new(2020, 12, 2, 12)) }
      let(:slot2) { described_class.new(Time.new(2020, 12, 2, 10, 30), Time.new(2020, 12, 2, 11, 30)) }

      it_behaves_like "intersects"
    end

    context "slot1 is after slot2" do
      # slot1               |-----|
      # slot2    |-----|
      let(:slot1) { described_class.new(Time.new(2020, 12, 2, 10, 30), Time.new(2020, 12, 2, 11, 30)) }
      let(:slot2) { described_class.new(Time.new(2020, 12, 2, 9), Time.new(2020, 12, 2, 10)) }

      it_behaves_like "does not intersect"
    end

    context "dates mismatch" do
      let(:slot1) { described_class.new(Time.new(2020, 12, 2, 10, 30), Time.new(2020, 12, 2, 11, 30)) }
      let(:slot2) { described_class.new(Time.new(2020, 12, 3, 10, 30), Time.new(2020, 12, 3, 11, 30)) }

      it_behaves_like "does not intersect"
    end
  end
end
