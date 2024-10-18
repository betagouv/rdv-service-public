class LongRequestNotifyMiddleware
  TIME_LIMIT = 10.seconds

  def initialize(app)
    @app = app
  end

  def call(env)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status, headers, response = @app.call(env)
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    duration = end_time - start_time
    if duration > TIME_LIMIT
      request_path = env["PATH_INFO"]
      Sentry.set_tags("request.duration": duration.round.to_s) # So we can view the distribution of durations
      Sentry.capture_message("Long request detected: #{request_path} took #{duration.round(2)} seconds")
    end

    [status, headers, response]
  end
end

Rails.configuration.middleware.use LongRequestNotifyMiddleware
