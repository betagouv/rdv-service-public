class Api::Rdvinsertion::InvitationsController < Api::V1::AgentAuthBaseController
  INVITATION_LINK_PARAMS = (InvitationSearchContext::INVITATION_PARAMS + %i[address latitude longitude invitation_token]).freeze

  def creneau_availability
    render json: { creneau_availability: creneau_available?, creneau_availability_count: number_of_creneaux_available }
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def user
    @user ||= Invitation.new(invitation_link_hash).user
  end

  def creneau_available?
    number_of_creneaux_available > 0
  end

  def number_of_creneaux_available
    @number_of_creneaux_available ||= invitation_search_context.matching_motifs.sum do |motif|
      if motif.phone?
        creneaux_available_for_motif(motif).size
      else
        motif.lieux.sum { |lieu| creneaux_available_for_motif(motif, lieu).size }
      end
    end
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
    params.permit(INVITATION_LINK_PARAMS)
  end
end
