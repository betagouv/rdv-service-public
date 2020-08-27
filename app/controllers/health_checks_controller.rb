class HealthChecksController < ApplicationController
  def rdv_events_stats
    @today_stats = RdvEvent.date_stats
    render(
      status: (thresholds_matched? ? :ok : :range_not_satisfiable),
      json: @today_stats
    )
  end

  private

  def thresholds_matched?
    if params[:min_mails].present?
      return false unless @today_stats[RdvEvent::TYPE_NOTIFICATION_MAIL]["total"] >= params[:min_mails].to_i
    end
    if params[:min_sms].present?
      return false unless @today_stats[RdvEvent::TYPE_NOTIFICATION_SMS]["total"] >= params[:min_sms].to_i
    end
    true
  end
end
