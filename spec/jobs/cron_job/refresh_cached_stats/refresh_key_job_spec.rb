# rubocop:disable RSpec/StubbedMock
RSpec.describe CronJob::RefreshCachedStats::RefreshKeyJob do
  before do
    allow(MetabaseApi).to receive(:authentication_present?).and_return(true)
  end

  context "chiffres reçus correctement" do
    specify do
      expect(MetabaseApi).to receive(:sql_query).and_return([{ "c" => "3 706 950" }])
      described_class.new.perform(key: "stats.both_instances.2_years.rdvs_count")
      expect(Rails.cache.fetch("stats.both_instances.2_years.rdvs_count")).to eq(3_706_950)
    end
  end

  context "chiffres formattés avec des virgules" do
    specify do
      expect(MetabaseApi).to receive(:sql_query).and_return([{ "c" => "3,706,950" }])
      described_class.new.perform(key: "stats.both_instances.2_years.rdvs_count")
      expect(Rails.cache.fetch("stats.both_instances.2_years.rdvs_count")).to eq(3_706_950)
    end
  end

  context "chiffres similaires dans le cache avant" do
    it "met à jour le cache" do
      Rails.cache.write("stats.both_instances.2_years.rdvs_count", 3_500_000)
      expect(MetabaseApi).to receive(:sql_query).and_return([{ "c" => "3 706 950" }])
      described_class.new.perform(key: "stats.both_instances.2_years.rdvs_count")
      expect(Rails.cache.fetch("stats.both_instances.2_years.rdvs_count")).to eq(3_706_950)
    end
  end

  context "chiffres qui paraissent aberrants" do
    it "ne remplace pas les valeurs dans le cache, valeurs aberrantes ignorées" do
      Rails.cache.write("stats.both_instances.2_years.rdvs_count", 3_500_000)
      expect(MetabaseApi).to receive(:sql_query).and_return([{ "c" => "3000" }])
      expect do
        described_class.new.perform(key: "stats.both_instances.2_years.rdvs_count")
      end.to raise_error(CronJob::RefreshCachedStats::SuspiciousFigureError)
      expect(Rails.cache.fetch("stats.both_instances.2_years.rdvs_count")).to eq(3_500_000)
    end
  end

  context "chiffres qui paraissent aberrants mais on force le rafraîchissement" do
    it "ne remplace pas les valeurs dans le cache, valeurs aberrantes ignorées" do
      Rails.cache.write("stats.both_instances.2_years.rdvs_count", 3_500_000)
      expect(MetabaseApi).to receive(:sql_query).and_return([{ "c" => "3000" }])
      expect do
        described_class.new.perform(key: "stats.both_instances.2_years.rdvs_count", force: true)
      end.not_to raise_error
      expect(Rails.cache.fetch("stats.both_instances.2_years.rdvs_count")).to eq(3_000)
    end
  end
end
# rubocop:enable RSpec/StubbedMock
