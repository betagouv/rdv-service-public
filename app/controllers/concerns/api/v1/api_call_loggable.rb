module Api::V1::ApiCallLoggable
  extend ActiveSupport::Concern

  included do
    attr_accessor :api_call
  end

  private

  def log_api_call_in_database
    raw_http = {
      method: request.method,
      path: request.fullpath,
      host: request.host,
    }

    self.api_call = ApiCall.create!(
      raw_http: raw_http,
      controller_name: controller_name,
      action_name: action_name,
      agent_id: current_agent.id,
      authentication_type: @authentication_type
    )
  rescue StandardError => e
    Sentry.capture_exception(e, extra: {
                               raw_http: raw_http,
                               controller_name: controller_name,
                               action_name: action_name,
                               agent_id: current_agent&.id,
                             })
  end

  def measure_execution_time
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    duration = end_time - start_time
    api_call.update(duration_in_ms: duration.in_milliseconds)
  end
end
