class Users::RdvBookingForm
  include Users::UserFormConcern
  include RdvBuilderConcern

  delegate :add_benign_error, :ignore_benign_errors, to: :user
  delegate :requires_ants_predemande_number?, to: :rdv

  validate :phone_number_present_for_motif_by_phone
  validates :ants_pre_demande_number, presence: true, if: :validate_ants?
  validates_with AntsPreDemandeNumberStatusValidation, if: :validate_ants?

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
    # we make sure the email can be updated only if it is blank
    @user.skip_reconfirmation! if @user.email_was.blank?

    valid? && @user.save
  end

  def ants_meeting_point_id = lieu_id

  def display_france_connect? = motif.organisation.online_booking_for_particuliers
  def display_pro_connect? = motif.organisation.online_booking_for_professionnels

  def show_birth_date_field? = !signed_in_with_invitation_token? && rdv.territory&.enable_birth_date_field?

  def show_ants_pre_demande_number_field? = rdv.requires_ants_predemande_number?

  def show_logement_field? = rdv.territory.enable_logement_field

  def show_address_field? = !signed_in_with_invitation_token? && rdv.territory.enable_address_field?

  def address_required? = motif.home?

  def phone_required? = motif.phone?

  def address_value = user.address.nil? ? to_query[:where] : user.address

  def show_social_fields? = service.nil? || service.user_field_groups.include?(:social)

  private

  def validate_ants?
    requires_ants_predemande_number? && @attributes[:user].present?
  end

  def phone_number_present_for_motif_by_phone
    errors.add(:phone_number, :missing_for_phone_motif) if rdv.motif.phone? && user.phone_number.blank?
  end
end
