class Api::V1::MotifsController < Api::V1::AgentAuthBaseController
  def index
    motifs = policy_scope(current_organisation.motifs, policy_scope_class: Agent::MotifPolicy::UseScope)
    motifs = motifs.active(params[:active].to_b) unless params[:active].nil?

    if params.key?(:bookable_publicly)
      motifs = if params[:bookable_publicly].to_b
                 motifs.bookable_by_everyone_or_bookable_by_invited_users
               else
                 motifs.not_bookable_by_everyone_or_not_bookable_by_invited_users
               end
    end

    motifs = motifs.where(service_id: params[:service_id]) if params[:service_id].present?

    motifs = motifs.with_motif_category_short_name(@params[:motif_category_short_name]) if params[:motif_category_short_name].present?

    render_collection(motifs.order(:id))
  end

  private

  def pundit_user
    current_agent
  end
end
