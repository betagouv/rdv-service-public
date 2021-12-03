# frozen_string_literal: true

describe SlotBuilder::BusyTime, type: :service do
  let(:monday) { Time.zone.parse("20211025 10:00") }
  let(:range) { Date.new(2021, 10, 26)..Date.new(2021, 10, 29) }
  let(:plage_ouverture) { create(:plage_ouverture) }

  before { travel_to(monday) }

  it "returns empty busy times without RDV or absence" do
    expect(described_class.busy_times_for(range, plage_ouverture)).to eq([])
  end

  context "with a RDV" do
    it "returns BusyTime object in array with a RDV" do
      create(:rdv, agents: [plage_ouverture.agent], starts_at: Time.zone.parse("20211027 9:00"))
      expect(described_class.busy_times_for(range, plage_ouverture).first).to be_a(described_class)
    end

    it "returns BusyTime that starts_at as RDV starts_at" do
      create(:rdv, agents: [plage_ouverture.agent], starts_at: Time.zone.parse("20211027 9:00"))
      expect(described_class.busy_times_for(range, plage_ouverture).first.starts_at).to eq(Time.zone.parse("20211027 9:00"))
    end

    it "returns BusyTime that ends_at as RDV ends_at" do
      create(:rdv, agents: [plage_ouverture.agent], starts_at: Time.zone.parse("20211027 9:00"), ends_at: Time.zone.parse("20211027 9:40"))
      expect(described_class.busy_times_for(range, plage_ouverture).first.ends_at).to eq(Time.zone.parse("20211027 9:40"))
    end
  end

  context "with an absence without recurrence" do
    it "returns BusyTime object in array" do
      create(:absence, agent: plage_ouverture.agent, organisation: plage_ouverture.organisation, first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9))
      expect(described_class.busy_times_for(range, plage_ouverture).first).to be_a(described_class)
    end

    it "returns BusyTime starts_at as absence first_day and start_time" do
      create(:absence, agent: plage_ouverture.agent, organisation: plage_ouverture.organisation, first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9))
      expect(described_class.busy_times_for(range, plage_ouverture).first.starts_at).to eq(Time.zone.parse("20211027 9:00"))
    end

    it "returns BusyTime ends_at as absence first_day and end_time when end_day is nil" do
      create(:absence, agent: plage_ouverture.agent, organisation: plage_ouverture.organisation, first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9), end_day: nil,
                       end_time: Tod::TimeOfDay.new(9, 40))
      expect(described_class.busy_times_for(range, plage_ouverture).first.ends_at).to eq(Time.zone.parse("20211027 9:40"))
    end

    it "returns BusyTime ends_at as absnce end_day and end_time" do
      create(:absence, agent: plage_ouverture.agent, organisation: plage_ouverture.organisation, first_day: Date.new(2021, 10, 27), start_time: Tod::TimeOfDay.new(9),
                       end_day: Date.new(2021, 10, 28), end_time: Tod::TimeOfDay.new(12))
      expect(described_class.busy_times_for(range, plage_ouverture).first.ends_at).to eq(Time.zone.parse("20211028 12"))
    end
  end

  context "with an absence with recurrence" do
    it "returns starts_at first occurrence in range" do
      create(:absence, agent: plage_ouverture.agent, organisation: plage_ouverture.organisation, first_day: Date.new(2021, 10, 19), start_time: Tod::TimeOfDay.new(9),
                       recurrence: Montrose.every(:week, on: ["tuesday"], starts: Time.zone.parse("20211019 9:00"), until: nil))
      expect(described_class.busy_times_for(range, plage_ouverture).first.starts_at).to eq(Time.zone.parse("20211026 9:00"))
    end

    it "returns ends_at occurrence in range" do
      create(:absence, agent: plage_ouverture.agent, organisation: plage_ouverture.organisation, first_day: Date.new(2021, 10, 19), start_time: Tod::TimeOfDay.new(9),
                       end_time: Tod::TimeOfDay.new(9, 45), recurrence: Montrose.every(:week, on: ["tuesday"], starts: Time.zone.parse("20211019 9:00"), until: nil))
      expect(described_class.busy_times_for(range, plage_ouverture).first.ends_at).to eq(Time.zone.parse("20211026 9:45"))
    end

    it "returns a busy_time for each occurrence in range" do
      create(:absence,
             agent: plage_ouverture.agent,
             organisation: plage_ouverture.organisation,
             first_day: Date.new(2021, 10, 19),
             start_time: Tod::TimeOfDay.new(9),
             end_time: Tod::TimeOfDay.new(9, 45),
             recurrence: Montrose.every(:week, on: %w[tuesday friday], starts: Time.zone.parse("20211019 9:00"), until: nil))
      expect(described_class.busy_times_for(range, plage_ouverture).map(&:ends_at)).to eq([Time.zone.parse("20211026 9:45"), Time.zone.parse("20211029 9:45")])
    end
  end

  context "with an off_day in range" do
    it "returns off_day from begninning of day to end of day" do
      off_days = [Date.new(2021, 10, 27)]
      expect(described_class.busy_times_for(range, plage_ouverture, off_days).first.starts_at).to eq(Time.zone.parse("20211027 0:00"))
      expect(described_class.busy_times_for(range, plage_ouverture, off_days).first.ends_at).to be_within(1.second).of(Time.zone.parse("20211027 23:59:59"))
    end
  end
end
