RSpec.describe CronJob::DestroyExternalCalendarSyncExecutionJob do
  it "supprime les executions anciennes" do
    execution_2_days_old = create(:external_calendar_sync_execution, :with_logs, started_at: 2.days.ago)
    _execution_3_days_old = create(:external_calendar_sync_execution, :with_logs, started_at: (3.days.ago - 2.minutes))
    _execution_4_days_old = create(:external_calendar_sync_execution, :with_logs, started_at: 4.days.ago)

    expect { described_class.new.perform }.to change(ExternalCalendarSyncExecution, :count).by(-2)

    expect(ExternalCalendarSyncExecution.all).to contain_exactly(execution_2_days_old)
  end
end
