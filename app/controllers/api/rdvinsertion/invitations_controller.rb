class Api::Rdvinsertion::InvitationsController < Api::V1::AgentAuthBaseController
  INVITATION_LINK_PARAMS = (InvitationSearchContext::INVITATION_PARAMS + %i[address latitude longitude invitation_token]).freeze

  def creneau_availability
    render json: { creneau_availability: creneau_available? }
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def user
    @user ||= Invitation.new(invitation_link_hash).user
  end

  def creneau_available?
    invitation_search_context.matching_motifs.any? do |motif|
      if motif.phone?
        creneaux_available_for_motif?(motif)
      else
        motif.lieux.any? { |lieu| creneaux_available_for_motif?(motif, lieu) }
      end
    end
  end

  def creneaux_available_for_motif?(motif, lieu = nil)
    CreneauxSearch::ForUser.new(
      user: user,
      motif: motif,
      lieu: lieu,
      geo_search: invitation_search_context.geo_search
    ).creneaux.any?
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
