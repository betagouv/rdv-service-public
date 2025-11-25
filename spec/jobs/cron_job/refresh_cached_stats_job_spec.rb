RSpec.describe CronJob::RefreshCachedStatsJob do
  before do
    allow(MetabaseApi).to receive(:authentication_present?).and_return(true)
  end

  context "chiffres reçus correctement" do
    specify do
      expect(MetabaseApi).to receive(:sql_query).twice.and_return(
        [{ "c" => "3 706 950" }],
        [{ "c" => "2,482" }]
      )
      described_class.new.perform
      expect(Rails.cache.fetch("stats.both_instances.2_years.rdvs_count")).to eq(3_706_950)
      expect(Rails.cache.fetch("stats.both_instances.2_years.active_organisations_count")).to eq(2_482)
    end
  end

  context "chiffres similaires dans le cache avant" do
    it "met à jour le cache" do
      Rails.cache.write("stats.both_instances.2_years.rdvs_count", 3_500_000)
      Rails.cache.write("stats.both_instances.2_years.active_organisations_count", 2_000)
      expect(MetabaseApi).to receive(:sql_query).twice.and_return(
        [{ "c" => "3 706 950" }],
        [{ "c" => "2,482" }]
      )
      described_class.new.perform
      expect(Rails.cache.fetch("stats.both_instances.2_years.rdvs_count")).to eq(3_706_950)
      expect(Rails.cache.fetch("stats.both_instances.2_years.active_organisations_count")).to eq(2_482)
    end
  end

  context "chiffres qui paraissent aberrants" do
    it "ne remplace pas les valeurs dans le cache, valeurs aberrantes ignorées" do
      Rails.cache.write("stats.both_instances.2_years.rdvs_count", 3_500_000)
      Rails.cache.write("stats.both_instances.2_years.active_organisations_count", 2_000)
      expect(MetabaseApi).to receive(:sql_query).twice.and_return(
        [{ "c" => "3000" }],
        [{ "c" => "20" }]
      )
      expect { described_class.new.perform }.to raise_error(CronJob::RefreshCachedStatsJob::SuspiciousFigureError)
      expect(Rails.cache.fetch("stats.both_instances.2_years.rdvs_count")).to eq(3_500_000)
      expect(Rails.cache.fetch("stats.both_instances.2_years.active_organisations_count")).to eq(2_000)
    end
  end

  context "chiffres qui paraissent aberrants mais on force le rafraîchissement" do
    it "ne remplace pas les valeurs dans le cache, valeurs aberrantes ignorées" do
      Rails.cache.write("stats.both_instances.2_years.rdvs_count", 3_500_000)
      Rails.cache.write("stats.both_instances.2_years.active_organisations_count", 2_000)
      expect(MetabaseApi).to receive(:sql_query).twice.and_return(
        [{ "c" => "3000" }],
        [{ "c" => "20" }]
      )
      expect { described_class.new.perform(force: true) }.not_to raise_error
      expect(Rails.cache.fetch("stats.both_instances.2_years.rdvs_count")).to eq(3_000)
      expect(Rails.cache.fetch("stats.both_instances.2_years.active_organisations_count")).to eq(20)
    end
  end
end
