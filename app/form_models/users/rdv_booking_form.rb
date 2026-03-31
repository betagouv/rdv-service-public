class Users::RdvBookingForm
  include Users::UserFormConcern

  attr_reader :rdv_builder

  delegate :to_query, :motif, :service, :rdv, to: :rdv_builder
  delegate :add_benign_error, :ignore_benign_errors, to: :user
  validates :ants_pre_demande_number, presence: true, if: -> { rdv.requires_ants_predemande_number? }
  validates_with AntsPreDemandeNumberStatusValidation, if: -> { rdv.requires_ants_predemande_number? }

  validate :validate_phone_number_present_for_motif_by_phone

  def initialize(user:, rdv_builder:, domain:, user_attributes: {})
    @user = user
    @rdv_builder = rdv_builder
    @domain = domain
    @user.assign_attributes(user_attributes)
  end

  def save
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

  def ants_meeting_point_id = rdv_builder.lieu_id

  private

  def validate_phone_number_present_for_motif_by_phone
    errors.add(:phone_number, :missing_for_phone_motif) if rdv.motif.phone? && user.phone_number.blank?
  end
end
