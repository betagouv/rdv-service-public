class Api::Rdvinsertion::InvitationsController < Api::V1::AgentAuthBaseController
  def creneau_availability
    payload = if params[:total_count] == "true"
                { creneau_availability_count:, limit_reached: relevant_limit_reached?(creneau_availability_count) }
              else
                { creneau_availability: creneau_available? }
              end

    render json: payload
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def creneau_availability_count
    @creneau_availability_count ||= begin
      counter = 0
      invitation_search_context.matching_motifs.each do |motif|
        if motif.phone?
          counter += creneaux_available_for_motif(motif).all_creneaux.size
        else
          motif.lieux.each do |lieu|
            counter += creneaux_available_for_motif(motif, lieu).all_creneaux.size
            break if relevant_limit_reached?(counter)
          end
        end
        break if relevant_limit_reached?(counter)
      end
      counter
    end
  end

  def creneau_available?
    invitation_search_context.matching_motifs.any? do |motif|
      if motif.phone?
        creneaux_available_for_motif(motif).creneaux.any?
      else
        motif.lieux.any? { |lieu| creneaux_available_for_motif(motif, lieu).creneaux.any? }
      end
    end
  end

  def relevant_limit_reached?(count)
    params[:max_relevant_creneaux_count_limit].present? && count >= params[:max_relevant_creneaux_count_limit].to_i
  end

  def creneaux_available_for_motif(motif, lieu = nil)
    CreneauxSearch::ForUser.new(
      user: user,
      motif: motif,
      lieu: lieu,
      geo_search: invitation_search_context.geo_search
    )
  end

  def invitation_search_context
    starting_conditions = CreneauWizardForUsers::StartingConditions.new
    @invitation_search_context ||= InvitationSearchContext.new(
      user: user,
      query_params: invitation_link_hash,
      starting_conditions:
    )
  end

  def user
    @user ||= Invitation.new(invitation_link_hash).user
  end

  def invitation_link_hash
    @invitation_link_hash ||= invitation_link_params.to_h.deep_symbolize_keys
  end

  def invitation_link_params
    # invitation_token sert uniquement à retrouver l'usager
    params.permit(InvitationSearchContext::INVITATION_PARAMS + %i[invitation_token])
  end
end
