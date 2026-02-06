class Users::RdvBookingForm
  include Users::UserFormConcern
  include RdvBuilderConcern

  delegate :ants_pre_demande_number, to: :user
  delegate :territory, :requires_ants_predemande_number?, to: :rdv

  validate :phone_number_present_for_motif_by_phone

  def initialize(user:, attributes:, domain:)
    @user = user
    @domain = domain

    # Gestion du created_user_id (pour step 2 - choix de l'usager)
    attributes = attributes.to_h.symbolize_keys
    if attributes[:created_user_id].present?
      attributes[:user_ids] = [attributes[:created_user_id]]
    end

    build_rdv_from_attributes(attributes)
    @user&.assign_attributes(attributes.fetch(:user, {}))
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

  def display_france_connect? = motif.organisation.online_booking_for_particuliers
  def display_pro_connect? = motif.organisation.online_booking_for_professionnels

  def current_organisation = motif.organisation

  def show_birth_date_field? = !signed_in_with_invitation_token? && territory&.enable_birth_date_field?

  def show_ants_pre_demande_number_field? = requires_ants_predemande_number?

  def show_address_field? = !signed_in_with_invitation_token? && current_organisation.territory.enable_address_field?

  def phone_required? = motif.phone?

  def address_required? = motif.home?

  def address_value = user.address.nil? ? to_query[:where] : user.address

  def show_social_fields? = service.nil? || service.user_field_groups.include?(:social)

  def show_logement_field? = current_organisation.territory.enable_logement_field

  private

  def phone_number_present_for_motif_by_phone
    errors.add(:phone_number, :missing_for_phone_motif) if rdv.motif.phone? && user.phone_number.blank?
  end
end
