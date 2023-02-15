# frozen_string_literal: true

class Api::V1::MotifsController < Api::V1::AgentAuthBaseController
  def index
    motifs = policy_scope(Motif)
    motifs = motifs.active(params[:active].to_b) unless params[:active].nil?

    motifs = motifs.where(bookable_publicly: params[:bookable_publicly].to_b) unless params[:bookable_publicly].nil?

    motifs = motifs.where(service_id: params[:service_id]) if params[:service_id].present?

    motifs = motifs.with_motif_category_short_name(@params[:motif_category_short_name]) if params[:motif_category_short_name].present?

    render_collection(motifs.order(:id))
  end
end
