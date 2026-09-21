class CronJob::RefreshAgentsSensitiveAccountJob < CronJob
  def perform
    return if disabled?

    AgentSensitiveAccountCalculator.refresh_all!
  end

  private

  def disabled?
    ENV["DISABLE_REFRESH_AGENTS_SENSITIVE_ACCOUNT_JOB"] == "true"
  end
end
