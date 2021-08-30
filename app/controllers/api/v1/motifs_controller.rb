# frozen_string_literal: true

class Api::V1::MotifsController < Api::V1::BaseController
  def index
    motifs = policy_scope(Motif)

    unless params[:active].nil?
      motifs = active_motifs? ? motifs.where(deleted_at: nil) : motifs.where.not(deleted_at: nil)
    end
    motifs = motifs.where(reservable_online: reservable_online_motifs?) unless params[:reservable_online].nil?

    render_collection(motifs.order(:id))
  end

  private

  def active_motifs?
    # falsy values can be found here: https://api.rubyonrails.org/classes/ActiveModel/Type/Boolean.html
    ActiveRecord::Type::Boolean.new.cast(params[:active])
  end

  def reservable_online_motifs?
    # falsy values can be found here: https://api.rubyonrails.org/classes/ActiveModel/Type/Boolean.html
    ActiveRecord::Type::Boolean.new.cast(params[:reservable_online])
  end
end
