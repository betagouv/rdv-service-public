class Users::RdvBookingForm
  include Users::UserFormConcern

  attr_reader :rdv_wizard

  delegate :to_query, :motif, :service, :rdv, to: :rdv_wizard

  validate :validate_phone_number_present_for_motif_by_phone

  def initialize(user:, rdv_wizard:, domain:, user_attributes: {})
    @user = user
    @rdv_wizard = rdv_wizard
    @domain = domain
    @user.assign_attributes(user_attributes)
  end

  def save
    # we make sure the email can be updated only if it is blank
    @user.skip_reconfirmation! if @user.email_was.blank?

    # dans la vue on appelle form_for(user) plutôt que form_for(user_rdv_wizard),
    # il faut donc ajouter des validations (et des erreurs) sur l'objet user
    if rdv.requires_ants_predemande_number?
      @user.singleton_class.include(User::AntsPreDemandeNumberStatusValidationConcern)
      @user.ants_meeting_point_id = rdv_wizard.lieu_id # used in AntsPreDemandeNumberStatusValidation
    end

    valid? && @user.save
  end

  def show_birth_date_field? = !signed_in_with_invitation_token? && rdv.territory&.enable_birth_date_field?

  def show_ants_pre_demande_number_field? = rdv.requires_ants_predemande_number?

  def show_logement_field? = rdv.territory.enable_logement_field

  def show_address_field? = !signed_in_with_invitation_token? && rdv.territory.enable_address_field?

  def address_required? = motif.home?

  def phone_required? = motif.phone?

  def address_value = user.address.nil? ? to_query[:where] : user.address

  def show_social_fields? = service.nil? || service.user_field_groups.include?(:social)

  private

  def validate_phone_number_present_for_motif_by_phone
    errors.add(:phone_number, :missing_for_phone_motif) if rdv.motif.phone? && user.phone_number.blank?
  end
end
