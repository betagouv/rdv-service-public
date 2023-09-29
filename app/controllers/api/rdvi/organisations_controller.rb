# frozen_string_literal: true

class Api::Rdvi::OrganisationsController < Api::V1::AgentAuthBaseController
  before_action :set_organisation

  def available_creneaux_count
    # render json: { available_creneaux_count: 0 }
    # return

    total_creneaux = calculate_total_creneaux
    render json: { available_creneaux_count: total_creneaux }

    # Quid de l'affichage dynamique dans rdvi si ils créent de nouveaux créneaux entre temps ? webhooks ?
    # Pas de cache possible car recalcul si nvx rdv collectif ou plage d'ouverture créée entre temps
  end

  private

  def set_organisation
    @organisation = Organisation.find(params[:id])
    authorize @organisation
  end

  def calculate_total_creneaux
    sc = initialize_search_context

    motifs = sc.unique_motifs_by_name_and_location_type
    date_range = compute_date_range

    total_creneaux = 0
    motifs.each do |motif|
      total_creneaux += if motif.collectif?
                          calculate_collective_creneaux(motif, date_range)
                        else
                          calculate_individual_creneaux(motif, date_range)
                        end
    end

    total_creneaux
  end

  def initialize_search_context
    SearchContext.new(
      user: nil,
      query_params: {
        motif_category_short_name: params[:motif_category_short_name],
        organisation_ids: [params[:id]],
      },
      through_invitation: true
    )
  end

  def compute_date_range
    max_delay = params[:max_delay].to_i
    Time.zone.today..(Time.zone.today + max_delay.days)
  end

  def calculate_collective_creneaux(motif, date_range)
    rdvs = Rdv.collectif_and_available_for_reservation.where(motif: motif, starts_at: date_range)
    rdvs.sum(&:remaining_seats)
  end

  def calculate_individual_creneaux(motif, date_range)
    total_creneaux = 0
    motif.lieux.each do |lieu|
      creneau_search = Users::CreneauxSearch.new(
        user: nil,
        motif: motif,
        lieu: lieu,
        date_range: date_range,
        geo_search: nil
      )
      total_creneaux += creneau_search.creneaux.count
    end
    total_creneaux
  end
end
