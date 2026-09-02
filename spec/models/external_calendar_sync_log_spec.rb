RSpec.describe ExternalCalendarSyncLog, type: :model do
  describe "validations" do
    it "requires an agent" do
      sync_log = build(:external_calendar_sync_log, agent: nil)
      expect(sync_log).not_to be_valid
      expect(sync_log.errors[:agent]).to be_present
    end

    it "requires started_at" do
      sync_log = build(:external_calendar_sync_log, started_at: nil)
      expect(sync_log).not_to be_valid
      expect(sync_log.errors[:started_at]).to be_present
    end

    it "is valid without an ended_at" do
      sync_log = build(:external_calendar_sync_log, ended_at: nil)
      expect(sync_log).to be_valid
    end

    it "is valid when ended_at is after started_at" do
      sync_log = build(:external_calendar_sync_log, started_at: 5.minutes.ago, ended_at: 2.minutes.ago)
      expect(sync_log).to be_valid
    end

    it "is invalid when ended_at is before started_at" do
      sync_log = build(:external_calendar_sync_log, started_at: 2.minutes.ago, ended_at: 5.minutes.ago)
      expect(sync_log).not_to be_valid
      expect(sync_log.errors[:ended_at]).to be_present
    end

    it "is valid when ended_at equals started_at" do
      now = Time.zone.now
      sync_log = build(:external_calendar_sync_log, started_at: now, ended_at: now)
      expect(sync_log).to be_valid
    end
  end

  describe "#status" do
    it "returns 'En cours' when there is no ended_at" do
      sync_log = described_class.new(started_at: Time.zone.now)
      expect(sync_log.status).to eq("En cours")
    end

    it "returns 'Succès' when ended and successful" do
      sync_log = described_class.new(started_at: 5.minutes.ago, ended_at: 2.minutes.ago, successful: true)
      expect(sync_log.status).to eq("Succès")
    end

    it "returns 'Échec' when ended and not successful" do
      sync_log = described_class.new(started_at: 5.minutes.ago, ended_at: 2.minutes.ago, successful: false)
      expect(sync_log.status).to eq("Échec")
    end
  end

  describe "#duration" do
    it "returns nil when the sync has not started" do
      sync_log = described_class.new
      expect(sync_log.duration).to be_nil
    end

    it "returns nil when the sync has not ended" do
      sync_log = described_class.new(started_at: Time.zone.now)
      expect(sync_log.duration).to be_nil
    end

    it "returns the elapsed time between started_at and ended_at" do
      freeze_time do
        sync_log = described_class.new(started_at: 5.minutes.ago, ended_at: 2.minutes.ago)
        expect(sync_log.duration).to eq(3.minutes)
      end
    end
  end

  describe "#start!" do
    it "sets started_at to now and persists the record" do
      sync_log = build(:external_calendar_sync_log, started_at: nil)
      now = Time.zone.parse("2026-09-01 10:00:00")

      travel_to(now) { sync_log.start! }

      expect(sync_log.started_at).to eq(now)
      expect(sync_log).to be_persisted
    end
  end

  describe "#log" do
    it "appends a message to text_logs" do
      sync_log = described_class.new

      sync_log.log("premier message")
      sync_log.log("second message")

      expect(sync_log.text_logs).to eq(["premier message", "second message"])
    end

    it "appends to an already populated text_logs" do
      sync_log = described_class.new(text_logs: ["message existant"])

      sync_log.log("nouveau message")

      expect(sync_log.text_logs).to eq(["message existant", "nouveau message"])
    end
  end

  describe "#flush!" do
    it "marks the sync as successful, sets ended_at to now and persists the record" do
      started_at = Time.zone.parse("2026-09-01 10:00:00")
      now = Time.zone.parse("2026-09-01 10:05:00")
      sync_log = create(:external_calendar_sync_log, started_at: started_at)

      travel_to(now) { sync_log.flush!(successful: true) }

      expect(sync_log.successful).to be(true)
      expect(sync_log.ended_at).to eq(now)
      expect(sync_log.reload.successful).to be(true)
    end

    it "marks the sync as failed" do
      sync_log = create(:external_calendar_sync_log)

      sync_log.flush!(successful: false)

      expect(sync_log.successful).to be(false)
    end
  end
end
