# frozen_string_literal: true

class WebInvitationSearchContext < InvitationSearchContext
  include Users::CreneauxWizardConcern
  attr_reader :errors, :query_params, :address, :city_code, :street_ban_id, :latitude, :longitude

  def initialize(user:, query_params: {})
    super
    @user_selected_organisation_id = query_params[:user_selected_organisation_id]
    @motif_id = query_params[:motif_id]
    @motif_name_with_location_type = query_params[:motif_name_with_location_type]
    @service_id = query_params[:service_id]
    @address = query_params[:address]
  end

  # dupliqué de WebSearchContext
  def filter_motifs(available_motifs)
    motifs = super
    motifs = motifs.search_by_name_with_location_type(@motif_name_with_location_type) if @motif_name_with_location_type.present?
    motifs = motifs.where(service_id: @service_id) if @service_id.present?
    motifs = motifs.where(organisation_id: organisation_id) if organisation_id.present?
    motifs = motifs.where(id: @motif_id) if @motif_id.present?
    motifs
  end

  def invitation?
    true
  end

  def prescripteur?
    false
  end

  def organisation_id
    @user_selected_organisation_id
  end
end
