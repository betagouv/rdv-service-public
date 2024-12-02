RSpec.describe CronMonitor do
  subject { described_class.expected_enqueued_count(cron_str, time_range) }

  context "cron tous les jours à 22h, time range entre 20h et 23h" do
    let(:cron_str) { "every day at 22:00 Europe/Paris" }
    let(:time_range) { (Time.zone.parse("2024-02-01 20:00")..Time.zone.parse("2024-02-01 23:00")) }

    it { is_expected.to eq 1 }
  end

  context "cron tous les jours à 22h, time range entre 18h et 20h" do
    let(:cron_str) { "every day at 22:00 Europe/Paris" }
    let(:time_range) { (Time.zone.parse("2024-02-01 18:00")..Time.zone.parse("2024-02-01 20:00")) }

    it { is_expected.to eq 0 }
  end

  context "cron toutes les 10 minutes de 9h à 18h, time range entre 10h et 10h58" do
    let(:cron_str) { "0/10 9,10,11,12,13,14,15,16,17,18 * * * Europe/Paris" }
    let(:time_range) { (Time.zone.parse("2024-02-01 10:00")..Time.zone.parse("2024-02-01 10:58")) }

    it { is_expected.to eq 5 }
  end
end
