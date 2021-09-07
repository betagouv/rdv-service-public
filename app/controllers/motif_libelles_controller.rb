# frozen_string_literal: true

class MotifLibellesController < ApplicationController
  def index
    return unless params[:service_id]

    motif_libelles = MotifLibelle.where(service_id: params[:service_id])
    respond_to do |format|
      format.json { render json: { motif_libelles: motif_libelles } }
    end
  end
end
