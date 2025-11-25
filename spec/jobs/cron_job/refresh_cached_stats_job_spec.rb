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
end
