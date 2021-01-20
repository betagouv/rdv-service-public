class HealthCheckControllerError < StandardError; end

class HealthChecksController < ApplicationController
  def rdv_events_stats
    @today_stats = RdvEvent.date_stats
    render(
      status: (thresholds_matched? ? :ok : :range_not_satisfiable),
      json: @today_stats
    )
  end

  def raise_on_purpose
    raise HealthCheckControllerError, "This is a test"
  end

  def enqueue_failing_job
    FailingJob.perform_later("first arg test", "second arg test", kwtest1: "somevalue")
    render body: "succesfully queued"
  end

  private

  def thresholds_matched?
    return false if params[:min_mails].present? && !@today_stats[RdvEvent::TYPE_NOTIFICATION_MAIL]["total"] >= params[:min_mails].to_i
    return false if params[:min_sms].present? && !@today_stats[RdvEvent::TYPE_NOTIFICATION_SMS]["total"] >= params[:min_sms].to_i

    true
  end
end
