class HealthChecksController < ApplicationController
  def rdv_events_stats
    render json: RdvEvent.date_stats
  end
end
