class UserRdvWizard
  include ActiveModel::Model

  attr_accessor :rdv, :user

  delegate :motif, :starts_at, :service, to: :rdv
  delegate :errors, to: :user

  validate :phone_number_present_for_motif_by_phone

  def initialize(user, attributes)
    @user = user
    @attributes = attributes.to_h.symbolize_keys

    if attributes[:rdv_collectif_id].present?
      @rdv = Rdv.collectif.bookable_by_everyone_or_agents_and_prescripteurs_or_invited_users.find(attributes[:rdv_collectif_id])
    else
      @rdv = Rdv.new({
        user_ids: [user&.id],
      }.merge(@attributes.slice(:starts_at, :user_ids, :motif_id)))
      @rdv.duration_in_min = duration_in_min
      @rdv.organisation_id = @rdv.motif.organisation_id
    end

    @user&.assign_attributes(@attributes.fetch(:user, {}))
  end

  def params_to_selections
    if @rdv.present?
      return @attributes.merge(service: @rdv.motif.service_id, motif_name_with_location_type: @rdv.motif.name_with_location_type)
    end

    @attributes
  end

  def creneau
    # La validation de ce paramètre ANTS est faite ici pour simplifier la gestion des cas problématiques
    # qui peuvent se produire aux étapes de prise de RDV pré sign-in et post-sign-in. Les autres params
    # sont très peu validés. Le cas d'erreur principal qui peut se produire est qu'aucun créneau ne soit
    # trouvé pour les params passés. On s'appuie donc sur ce cas pour gérer l'erreur de validation ANTS
    return nil if ants_pre_demandes_count.present? && !AntsPreDemandesCountValidator.count_valid?(ants_pre_demandes_count)

    @creneau ||= CreneauxSearch::ForUser.creneau_for(
      user: @user,
      motif: motif,
      lieu: lieu,
      starts_at: @rdv.starts_at,
      geo_search: geo_search,
      duration_in_min:
    )
  end

  def geo_search
    @geo_search ||= Users::GeoSearch.new(**@attributes.slice(:departement, :city_code, :street_ban_id))
  end

  def to_query
    {
      motif_id: rdv.motif.id, starts_at: rdv.starts_at.to_s, user_ids: users&.map(&:id), rdv_collectif_id: rdv.id,
    }.merge(
      @attributes.slice(
        *WebSearchContext::ADDRESS_SELECTION_PARAMS,
        :where, :lieu_id, :organisation_ids, :public_link_organisation_id, :user_selected_organisation_id,
        :referent_ids, :external_organisation_ids, :duration, :ants_pre_demandes_count
      )
    )
  end

  def save
    # Les étapes 2 et 3 ne modifient pas les attributs de l'utilisateur
    return true if @attributes[:user].blank?

    # we make sure the email can be updated only if it is blank
    @user.skip_reconfirmation! if @user.email_was.blank?

    # dans la vue on appelle form_for(user) plutôt que form_for(user_rdv_wizard),
    # il faut donc ajouter des validations (et des erreurs) sur l'objet user
    if rdv.requires_ants_predemande_number?
      @user.singleton_class.include(User::AntsPreDemandeNumberStatusValidationConcern)
      @user.ants_meeting_point_id = lieu_id # used in AntsPreDemandeNumberStatusValidation
    end

    valid? && @user.save
  end

  def lieu_id = @attributes[:lieu_id]
  def ants_pre_demandes_count = @attributes[:ants_pre_demandes_count].presence&.to_i

  def duration_in_min
    if @attributes[:duration]
      @attributes[:duration].to_i
    elsif @attributes[:ants_pre_demandes_count].present?
      motif.default_duration_in_min * @attributes[:ants_pre_demandes_count].to_i
    else
      motif.default_duration_in_min
    end
  end

  def users
    if @rdv.collectif?
      return [] unless @user

      @user.available_users_for_rdv.where(id: @attributes[:user_ids]).presence || [@user]
    else
      @rdv.users.presence || [@user].compact
    end
  end

  def display_france_connect?
    motif.organisation.online_booking_for_particuliers
  end

  def display_pro_connect?
    motif.organisation.online_booking_for_professionnels
  end

  private

  def lieu
    @lieu ||= lieu_id.present? ? Lieu.find(lieu_id) : nil
  end

  def phone_number_present_for_motif_by_phone
    errors.add(:phone_number, :missing_for_phone_motif) if rdv.motif.phone? && user.phone_number.blank?
  end
end
