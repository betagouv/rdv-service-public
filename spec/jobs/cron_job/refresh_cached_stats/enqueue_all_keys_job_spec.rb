RSpec.describe CronJob::RefreshCachedStats::EnqueueAllKeysJob do
  before do
    allow(MetabaseApi).to receive(:authentication_present?).and_return(true)
  end

  specify do
    expect(CronJob::RefreshCachedStats::RefreshKeyJob).to receive(:perform_later).at_least(:once)
    described_class.new.perform
  end
end
