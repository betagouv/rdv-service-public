# frozen_string_literal: true

class Api::V1::MotifsController < Api::V1::AgentAuthBaseController
  def index
    motifs = policy_scope(Motif)
    motifs = motifs.active(params[:active].to_b) unless params[:active].nil?

    motifs = motifs.where(reservable_online: params[:reservable_online].to_b) unless params[:reservable_online].nil?

    motifs = motifs.where(service_id: params[:service_id]) if params[:service_id].present?

    motifs = motifs.where(category: params[:category]) if params[:category].present?

    render_collection(motifs.order(:id))
  end
end
