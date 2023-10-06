# frozen_string_literal: true

class Api::Rdvi::InvitationsController < Api::V1::AgentAuthBaseController
  def available_creneaux_count
    total_creneaux = calculate_total_creneaux
    render json: { available_creneaux_count: total_creneaux }
  end

  private

  def user
    @user ||= invitation_link_hash[:invitation_token].present? ? Invitation.new(invitation_link_hash).user : nil
  end

  def calculate_total_creneaux
    total_creneaux = 0
    invitation_search_context.matching_motifs.each do |motif|
      total_creneaux += calculate_creneaux(motif)
    end
    total_creneaux
  end

  def invitation_search_context
    @invitation_search_context ||= InvitationSearchContext.new(
      user: user,
      query_params: invitation_link_hash
    )
  end

  def calculate_creneaux(motif)
    total_creneaux_for_motif_lieux = 0

    motif.lieux.each do |lieu|
      creneau_search = Users::CreneauxSearch.new(
        user: user,
        motif: motif,
        lieu: lieu,
        geo_search: invitation_search_context.geo_search
      )
      total_creneaux_for_motif_lieux += creneau_search.creneaux.count
    end
    total_creneaux_for_motif_lieux
  end

  def invitation_link_hash
    @invitation_link_hash ||= invitation_link_params.to_h.deep_symbolize_keys
  end

  def invitation_link_params
    params.permit(
      :address,
      :city_code,
      :departement,
      :invitation_token,
      :latitude,
      :longitude,
      :organisation_ids,
      :street_ban_id,
      :motif_category_short_name,
      :lieu_id,
      :referent_ids
    )
  end
end
