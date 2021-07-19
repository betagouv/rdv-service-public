# frozen_string_literal: true

class Api::V1::MotifsController < Api::V1::BaseController
  def index
    motifs = policy_scope(Motif)
    motifs = motifs.active if params[:active] == "true"
    motifs = motifs.reservable_online if params[:reservable_online] == "true"
    render_collection(motifs.order(:id))
  end
end
