# frozen_string_literal: true

class SearchContext
  attr_reader :errors, :query, :departement, :address, :city_code, :street_ban_id, :latitude, :longitude,
              :motif_name_with_location_type

  def initialize(current_user, query = {})
    @current_user = current_user
    @query = query
    @invitation_token = query[:invitation_token]
    @latitude = query[:latitude]
    @longitude = query[:longitude]
    @address = query[:address]
    @city_code = query[:city_code]
    @departement = query[:departement]
    @street_ban_id = query[:street_ban_id]
    @public_link_organisation_id = query[:public_link_organisation_id]
    @user_selected_organisation_id = query[:user_selected_organisation_id]
    @fallback_organisation_ids = query[:organisation_ids]
    @motif_id = query[:motif_id]
    @motif_search_terms = query[:motif_search_terms]
    @motif_category = query[:motif_category]
    @motif_name_with_location_type = query[:motif_name_with_location_type]
    @service_id = query[:service_id]
    @lieu_id = query[:lieu_id]
    @start_date = query[:date]
  end

  # *** Method that outputs the next step for the user to complete its rdv journey ***
  # *** It is used in #to_partial_path to render the matching partial view ***
  def current_step
    if address.blank? && organisation_id.blank?
      :address_selection
    elsif !service_selected?
      :service_selection
    elsif !motif_name_and_type_selected?
      :motif_selection
    elsif requires_lieu_selection?
      :lieu_selection
    elsif requires_organisation_selection?
      :organisation_selection
    else
      :creneau_selection
    end
  end

  def to_partial_path
    "search/#{current_step}"
  end

  def geo_search
    Users::GeoSearch.new(departement: @departement, city_code: @city_code, street_ban_id: @street_ban_id)
  end

  def invitation?
    @invitation_token.present?
  end

  def service
    @service ||= if @service_id.present?
                   Service.find(@service_id)
                 elsif motif_name_and_type_selected?
                   first_matching_motif.service
                 elsif services.count == 1
                   services.first
                 end
  end

  def services
    unique_motifs_by_name_and_location_type.map(&:service).uniq.sort_by(&:name)
  end

  def requires_organisation_selection?
    !first_matching_motif.requires_lieu? && user_selected_organisation.nil? && public_link_organisation.nil?
  end

  def user_selected_organisation
    @user_selected_organisation ||= \
      @user_selected_organisation_id.present? ? Organisation.find(@user_selected_organisation_id) : nil
  end

  def public_link_organisation
    @public_link_organisation ||= \
      @public_link_organisation_id.present? ? Organisation.find(@public_link_organisation_id) : nil
  end

  def organisation_id
    @public_link_organisation_id || @user_selected_organisation_id
  end

  def motifs_organisations
    matching_motifs.map(&:organisation).uniq
  end

  def unique_motifs_by_name_and_location_type
    @unique_motifs_by_name_and_location_type ||= matching_motifs.uniq { [_1.name, _1.location_type] }
  end

  def first_matching_motif
    return unless motif_name_and_type_selected?

    matching_motifs.first
  end

  def motif_name_and_type_selected?
    unique_motifs_by_name_and_location_type.length == 1
  end

  def service_selected?
    service.present?
  end

  def requires_lieu_selection?
    first_matching_motif.requires_lieu? && lieu.nil?
  end

  def lieu
    @lieu ||= @lieu_id.blank? ? nil : Lieu.find(@lieu_id)
  end

  def lieux
    @lieux ||= \
      Lieu
        .with_open_slots_for_motifs(@matching_motifs)
        .includes(:organisation)
        .sort_by { |lieu| lieu.distance(@latitude.to_f, @longitude.to_f) }
  end

  def next_availability_by_lieux
    @next_availability_by_lieux ||= lieux.index_with do |lieu|
      creneaux_search_for(
        lieu, date_range, matching_motifs.where(organisation: lieu.organisation).first
      ).next_availability
    end.compact
  end

  def shown_lieux
    next_availability_by_lieux.keys
  end

  def start_date
    @start_date&.to_date || Time.zone.today
  end

  def date_range
    start_date..(start_date + 6.days)
  end

  def max_booking_delay
    matching_motifs.maximum("max_booking_delay")
  end

  def creneaux
    @creneaux ||= if first_matching_motif.collectif?
                    SearchRdvCollectif.creneaux(first_matching_motif, lieu)
                  else
                    creneaux_search.creneaux
                  end
  end

  def creneaux_search
    creneaux_search_for(lieu, date_range, first_matching_motif)
  end

  def next_availability
    @next_availability ||= creneaux.empty? ? creneaux_search.next_availability : nil
  end

  def filter_motifs(available_motifs)
    motifs = available_motifs
    motifs = motifs.search_by_name_with_location_type(@motif_name_with_location_type) if @motif_name_with_location_type.present?
    motifs = motifs.where(service: service) if @service_id.present?
    motifs = motifs.search_by_text(@motif_search_terms) if @motif_search_terms.present?
    motifs = motifs.where(category: @motif_category) if @motif_category.present?
    motifs = motifs.where(organisations: { id: organisation_id }) if organisation_id.present?
    motifs = motifs.where(id: @motif_id) if @motif_id.present?
    motifs = motifs.where(id: lieu_filtered_motif_ids(motifs)) if @lieu_id.present?

    motifs
  end

  private

  def lieu_filtered_motif_ids(motifs)
    # filtrer sur le `lieu_id` dans la table des plages d'ouverture permet de limiter de combiner et construire trop d'objet
    # voir https://github.com/betagouv/rdv-solidarites.fr/issues/2686
    motif_ids = motifs.individuel.joins(:plage_ouvertures).where(plage_ouvertures: { lieu_id: @lieu_id }).uniq.pluck(:id)

    # Pour prendre en compte le filtre sur le lieu_id pour les RDV Collectif,
    # nous ne pouvons pas passer par une requête `or` qui nécessite les mêmes jointures des deux côtés.
    motifs.collectif.each { |motif| motif_ids << motif.id if Rdv.exists?(lieu_id: @lieu_id, motif: motif) }

    motif_ids
  end

  def creneaux_search_for(lieu, date_range, motif)
    if motif.individuel?
      Users::CreneauxSearch.new(
        user: @current_user,
        motif: motif,
        lieu: lieu,
        date_range: date_range,
        geo_search: geo_search
      )
    else
      SearchRdvCollectif.next_availability_for_lieu(motif, lieu)
    end
  end

  def matching_motifs
    @matching_motifs ||= \
      if invitation?
        # we retrieve the geolocalised matching motifs, if there are none we fallback
        # on the matching motifs for the organisations passed in the query
        filter_motifs(geo_search.available_motifs).presence || filter_motifs(
          Motif.available_with_plages_ouvertures.where(organisation_id: @fallback_organisation_ids)
        )
      else
        filter_motifs(geo_search.available_motifs)
      end
  end
end
