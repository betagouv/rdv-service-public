class Api::Rdvinsertion::InvitationsController < Api::Rdvinsertion::AgentAuthBaseController
  def creneau_availability
    payload = if params[:total_count] == "true"
                { creneau_availability_count:, limit_reached: relevant_limit_reached?(creneau_availability_count) }
              else
                { creneau_availability: creneau_available? }
              end

    render json: payload
  end

  private

  def user
    @user ||= Invitation.new(invitation_link_hash).user
  end

  def creneau_availability_count
    @creneau_availability_count ||= begin
      counter = 0
      invitation_search_context.matching_motifs.each do |motif|
        if motif.public_office?
          motif.lieux.each do |lieu|
            counter += creneaux_available_for_motif(motif, lieu).all_creneaux.size
            break if relevant_limit_reached?(counter)
          end
        else
          counter += creneaux_available_for_motif(motif).all_creneaux.size
        end
        break if relevant_limit_reached?(counter)
      end
      counter
    end
  end

  def creneau_available?
    invitation_search_context.matching_motifs.any? do |motif|
      if motif.public_office?
        motif.lieux.any? { |lieu| creneaux_available_for_motif(motif, lieu).creneaux.any? }
      else
        creneaux_available_for_motif(motif).creneaux.any?
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
