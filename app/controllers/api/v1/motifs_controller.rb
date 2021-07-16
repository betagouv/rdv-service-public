# frozen_string_literal: true

class Api::V1::MotifsController < Api::V1::BaseController
  def index
    motifs = policy_scope(Motif)
    render_collection(motifs.order(:id))
  end
end
