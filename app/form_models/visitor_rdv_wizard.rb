class VisitorRdvWizard
  include ActiveModel::Model

  attr_accessor :rdv, :user, :pour_un_proche, :rdv_plan

  delegate :motif, :starts_at, :service, to: :rdv
  delegate :first_name, :last_name, :phone_number, to: :user

  validate :validate_user

  def initialize(attributes)
    @attributes = attributes.to_h.symbolize_keys
    @user = User.new(@attributes[:user]&.to_h&.symbolize_keys&.slice(:first_name, :last_name, :phone_number))
    if attributes[:rdv_collectif_id].present?
      @rdv = Rdv.collectif.bookable_by_everyone_or_agents_and_prescripteurs_or_invited_users.find(attributes[:rdv_collectif_id])
    else
      @rdv = Rdv.new(@attributes.slice(:starts_at, :user_ids, :motif_id))
      @rdv.duration_in_min = duration_in_min
      @rdv.organisation_id = @rdv.motif.organisation_id
    end
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
    # sont très peu validés. Le cas d’erreur principal qui peut se produire est qu’aucun créneau ne soit
    # trouvé pour les params passés. On s’appuie donc sur ce cas pour gérer l’erreur de validation ANTS
    return nil if ants_pre_demandes_count.present? && !AntsPreDemandesCountValidator.count_valid?(ants_pre_demandes_count)

    @creneau ||= CreneauxSearch::ForUser.creneau_for(
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
      motif_id: rdv.motif.id, starts_at: rdv.starts_at.to_s, rdv_collectif_id: rdv.id,
    }.merge(
      @attributes.slice(
        *WebSearchContext::ADDRESS_SELECTION_PARAMS,
        :where, :lieu_id, :organisation_ids, :public_link_organisation_id, :user_selected_organisation_id,
        :referent_ids, :external_organisation_ids, :duration, :ants_pre_demandes_count
      )
    )
  end

  def build_rdv_plan
    RdvPlan.new(
      user:,
      duration_in_minutes:,
      # organisation_id: rdv.motif.organisation_id,
      motif_id: rdv.motif.id,
      location_type: rdv.motif.location_type,
      rdv_agent_id: creneau.agent.id,
      lieu_id: @attributes[:lieu_id],
      starts_at:
    )
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

  alias duration_in_minutes duration_in_min

  # def users
  #   if @rdv.collectif?
  #     return [] unless @user
  #
  #     @user.available_users_for_rdv.where(id: @attributes[:user_ids]).presence || [@user]
  #   else
  #     @rdv.users.presence || [@user].compact
  #   end
  # end

  def display_france_connect?
    motif.organisation.online_booking_for_particuliers
  end

  def display_pro_connect?
    motif.organisation.online_booking_for_professionnels
  end

  # On a parfois besoin de cette méthode avant d'avoir une instance de RdvWizard, donc on factorise l'implémentation
  # avec cette méthode de classe
  def self.skip_proches_step?(user)
    # L'étape 2 propose de prendre rendez-vous pour un proche
    # Dans le cas d'une invitation, c'est l'usager qui est invité, donc on saute cette étape
    # Si l'usager est un professionnel connecté via ProConnect, on ne lui propose pas non plus de prendre rendez-vous pour un proche
    user.signed_in_with_invitation_token? || user.pro_connect_openid_sub
  end

  def skip_proches_step?
    self.class.skip_proches_step?(user)
  end

  private

  def lieu
    @lieu ||= lieu_id.present? ? Lieu.find(lieu_id) : nil
  end

  def validate_user
    user.singleton_class.validates :phone_number, presence: true
    user.validate
    user.errors.blank?
  end
end
