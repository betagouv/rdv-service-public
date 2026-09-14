RSpec.describe ExternalCalendarSyncExecution, type: :model do
  describe "validations" do
    it "requires an agent" do
      sync_execution = build(:external_calendar_sync_execution, agent: nil)
      expect(sync_execution).not_to be_valid
      expect(sync_execution.errors[:agent]).to be_present
    end

    it "requires started_at" do
      sync_execution = build(:external_calendar_sync_execution, started_at: nil)
      expect(sync_execution).not_to be_valid
      expect(sync_execution.errors[:started_at]).to be_present
    end

    it "is valid without an ended_at" do
      sync_execution = build(:external_calendar_sync_execution, ended_at: nil)
      expect(sync_execution).to be_valid
    end

    it "is valid when ended_at is after started_at" do
      sync_execution = build(:external_calendar_sync_execution, started_at: 5.minutes.ago, ended_at: 2.minutes.ago)
      expect(sync_execution).to be_valid
    end

    it "is invalid when ended_at is before started_at" do
      sync_execution = build(:external_calendar_sync_execution, started_at: 2.minutes.ago, ended_at: 5.minutes.ago)
      expect(sync_execution).not_to be_valid
      expect(sync_execution.errors[:ended_at]).to be_present
    end

    it "is valid when ended_at equals started_at" do
      now = Time.zone.now
      sync_execution = build(:external_calendar_sync_execution, started_at: now, ended_at: now)
      expect(sync_execution).to be_valid
    end
  end

  describe "#status" do
    it "returns 'En cours' when there is no ended_at" do
      sync_execution = described_class.new(started_at: Time.zone.now)
      expect(sync_execution.status).to eq("En cours")
    end

    it "returns 'Succès' when ended and successful" do
      sync_execution = described_class.new(started_at: 5.minutes.ago, ended_at: 2.minutes.ago, successful: true)
      expect(sync_execution.status).to eq("Succès")
    end

    it "returns 'Échec' when ended and not successful" do
      sync_execution = described_class.new(started_at: 5.minutes.ago, ended_at: 2.minutes.ago, successful: false)
      expect(sync_execution.status).to eq("Échec")
    end
  end

  describe "#duration" do
    it "returns nil when the sync has not started" do
      sync_execution = described_class.new
      expect(sync_execution.duration).to be_nil
    end

    it "returns nil when the sync has not ended" do
      sync_execution = described_class.new(started_at: Time.zone.now)
      expect(sync_execution.duration).to be_nil
    end

    it "returns the elapsed time between started_at and ended_at" do
      freeze_time do
        sync_execution = described_class.new(started_at: 5.minutes.ago, ended_at: 2.minutes.ago)
        expect(sync_execution.duration).to eq(3.minutes)
      end
    end
  end

  describe "#start!" do
    it "sets started_at to now and persists the record" do
      sync_execution = build(:external_calendar_sync_execution, started_at: nil)
      now = Time.zone.parse("2026-09-01 10:00:00")

      travel_to(now) { sync_execution.start! }

      expect(sync_execution.started_at).to eq(now)
      expect(sync_execution).to be_persisted
    end
  end

  describe "#log" do
    it "persists a log entry with the current time" do
      sync_execution = create(:external_calendar_sync_execution)
      now = Time.zone.parse("2026-09-01 10:00:00")

      travel_to(now) { sync_execution.log("premier message") }

      expect(sync_execution.logs.pluck(:message, :emitted_at)).to eq([["premier message", now]])
    end

    it "appends to already existing log entries" do
      sync_execution = create(:external_calendar_sync_execution)
      sync_execution.log("premier message")

      sync_execution.log("second message")

      expect(sync_execution.logs.order(:emitted_at).pluck(:message)).to eq(["premier message", "second message"])
    end
  end

  describe "#finalize!" do
    it "marks the sync as successful, sets ended_at to now and persists the record" do
      started_at = Time.zone.parse("2026-09-01 10:00:00")
      now = Time.zone.parse("2026-09-01 10:05:00")
      sync_execution = create(:external_calendar_sync_execution, started_at: started_at)

      travel_to(now) { sync_execution.finalize!(successful: true) }

      expect(sync_execution.successful).to be(true)
      expect(sync_execution.ended_at).to eq(now)
      expect(sync_execution.reload.successful).to be(true)
    end

    it "marks the sync as failed" do
      sync_execution = create(:external_calendar_sync_execution)

      sync_execution.finalize!(successful: false)

      expect(sync_execution.successful).to be(false)
    end
  end
end
