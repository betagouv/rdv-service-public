RSpec.describe WebhookExecution do
  describe ".record_execution!" do
    it "set the day to today" do
      described_class.record_execution!(webhook_endpoint_id: create(:webhook_endpoint).id, http_code: 200)
      expect(described_class.last.day).to eq(Time.zone.today)

      travel_to(Date.new(2025, 12, 22)) do
        described_class.record_execution!(webhook_endpoint_id: create(:webhook_endpoint).id, http_code: 200)
        expect(described_class.last.day).to eq(Date.new(2025, 12, 22))
      end

      expect(described_class.count).to eq(2)
    end

    it "increments the counter when called with the same :url and :http_code values" do
      webhook_endpoint = create(:webhook_endpoint, target_url: "https://hooks.net/123")

      expect(described_class.count).to eq(0)

      5.times do
        described_class.record_execution!(
          webhook_endpoint_id: webhook_endpoint.id,
          http_code: 200
        )
      end
      expect(described_class.count).to eq(1)
      expect(described_class.last).to have_attributes(
        counter: 5
      )
    end

    it "creates a different record for each URL" do
      webhook_endpoint1 = create(:webhook_endpoint, target_url: "https://hooks.net/123")
      webhook_endpoint2 = create(:webhook_endpoint, target_url: "https://other.com/456789")
      3.times { described_class.record_execution!(webhook_endpoint_id: webhook_endpoint1.id, http_code: 200) }
      5.times { described_class.record_execution!(webhook_endpoint_id: webhook_endpoint2.id, http_code: 200) }

      expect(described_class.count).to eq(2)
      expect(described_class.find_by(webhook_endpoint: webhook_endpoint1).counter).to eq(3)
      expect(described_class.find_by(webhook_endpoint: webhook_endpoint2).counter).to eq(5)
    end

    it "creates a different record for each HTTP code" do
      webhook_endpoint = create(:webhook_endpoint, target_url: "https://hooks.net/123")
      2.times { described_class.record_execution!(webhook_endpoint_id: webhook_endpoint.id, http_code: 200) }
      5.times { described_class.record_execution!(webhook_endpoint_id: webhook_endpoint.id, http_code: 500) }

      expect(described_class.count).to eq(2)
      expect(described_class.find_by(webhook_endpoint: webhook_endpoint, http_code: 200).counter).to eq(2)
      expect(described_class.find_by(webhook_endpoint: webhook_endpoint, http_code: 500).counter).to eq(5)
    end
  end
end
