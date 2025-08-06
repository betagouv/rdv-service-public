class WebInvitationSearchContext < InvitationSearchContext
  attr_reader :errors, :query_params, :organisation_ids, :motif_category_short_name, :autofocus

  def initialize(user:, query_params: {})
    super

    # User choices
    # La plupart du temps il n'y a qu'un seul service qui propose des invitations, donc il n'est
    # pas choisi explicitement, mais c'est techniquement possible
    @service_id = query_params[:service_id]
    # motif_selection:
    @motif_name_with_location_type = query_params[:motif_name_with_location_type]

    # lieu_selection: le lieu peut parfois être déterminé par l'invitation
    # mais il peut aussi être choisi par l'usager.
    # Dans les deux cas, la variable d'instance lieu_id est initialisée par la classe parente

    # organisation_selection:
    @user_selected_organisation_id = query_params[:user_selected_organisation_id]

    # creneau_selection
    @motif_id = query_params[:motif_id]

    # Pour des questions d’accessibilité, on met le focus sur le premier ou le dernier créneau lorsqu’on clique
    # sur les boutons semaine précédente ou semaine suivante.
    @autofocus = query_params.delete(:autofocus)
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

  def public_link_organisation
    # public_link_organisation is not used in web invitation context
    nil
  end

  def motif_param_present?
    @motif_id.present? ||
      @motif_name_with_location_type.present? ||
      @motif_category_short_name.present?
  end
end
