class Api::Rdvinsertion::InvitationsController < Api::V1::AgentAuthBaseController
  MAX_RELEVANT_CRENEAUX_COUNT_LIMIT = 200

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

  def user
    @user ||= Invitation.new(invitation_link_hash).user
  end

  def creneau_availability_count
    @creneau_availability_count ||= begin
      available_creneaux_count = 0
      invitation_search_context.matching_motifs.each do |motif|
        if motif.phone?
          creneaux_available_for_motif(motif).size
        else
          motif.lieux.each do |lieu|
            available_creneaux_count += creneaux_available_for_motif(motif, lieu).size
            break if relevant_limit_reached?(available_creneaux_count)
          end
        end
        break if relevant_limit_reached?(available_creneaux_count)
      end
      available_creneaux_count
    end
  end

  def creneau_available?
    invitation_search_context.matching_motifs.any? do |motif|
      if motif.phone?
        creneaux_available_for_motif(motif).any?
      else
        motif.lieux.any? { |lieu| creneaux_available_for_motif(motif, lieu).any? }
      end
    end
  end

  def relevant_limit_reached?(count)
    count >= MAX_RELEVANT_CRENEAUX_COUNT_LIMIT
  end

  def creneaux_available_for_motif(motif, lieu = nil)
    CreneauxSearch::ForUser.new(
      user: user,
      motif: motif,
      lieu: lieu,
      geo_search: invitation_search_context.geo_search
    ).creneaux
  end

  def invitation_search_context
    @invitation_search_context ||= InvitationSearchContext.new(
      user: user,
      query_params: invitation_link_hash
    )
  end

  def invitation_link_hash
    @invitation_link_hash ||= invitation_link_params.to_h.deep_symbolize_keys
  end

  def invitation_link_params
    # invitation_token sert uniquement à retrouver l'usager
    params.permit(InvitationSearchContext::INVITATION_PARAMS + %i[invitation_token])
  end
end
