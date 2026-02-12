class UserRdvWizard
  include ActiveModel::Model
  include RdvBuilderConcern

  attr_accessor :user

  delegate :errors, to: :user

  validate :phone_number_present_for_motif_by_phone

  def initialize(user, attributes)
    @user = user
    build_rdv_from_attributes(attributes)

    @user&.assign_attributes(@attributes.fetch(:user, {}))
  end

  def save
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
