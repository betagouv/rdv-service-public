module Users::UserFormConcern
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model

    def self.human_attribute_name(...) = User.human_attribute_name(...)

    attr_reader :user, :domain

    delegate :first_name, :last_name, :birth_name, :birth_date,
             :phone_number, :phone_number_mobile?,
             :email, :email_changed?, :notification_email,
             :address, :address_details,
             :city_code, :post_code, :city_name,
             :caisse_affiliation, :affiliation_number, :logement,
             :notify_by_email, :notify_by_sms,
             :connected_with_sso?, :pro_connect_openid_sub,
             :logged_once_with_franceconnect?,
             :signed_in_with_invitation_token?,
             :errors, :errors_are_all_benign?, :benign_errors,
             to: :user
  end

  def territories
    @territories ||= Territory.joins(organisations: :user_profiles).where(user_profiles: { user_id: user.id }).to_a
  end

  def show_birth_name_field?
    !signed_in_with_invitation_token? && domain != Domain::RDV_SERVICE_PUBLIC && !pro_connect_openid_sub
  end

  def first_name_frozen? = connected_with_sso?
  def last_name_frozen? = pro_connect_openid_sub.present?
  def birth_name_frozen? = connected_with_sso?
  def birth_date_frozen? = logged_once_with_franceconnect?

  def show_franceconnect_frozen_fields_warning? = logged_once_with_franceconnect?
  def show_ants_pre_demande_number_field? = false

  # Pour des raisons historiques on garde le champ email pour les usagers invités qui en ont un
  def show_email_field? = signed_in_with_invitation_token? && email.present?
  def email_disabled? = email.present? && !email_changed?

  # L'usager peut définir un email de notification s'il n'en a pas encore, mais ce n'est pas obligatoire.
  # Par contre on ne veut pas perdre d'info si l'usager a déjà un email de notification, donc le champ est requis.
  def show_notification_email_field?
    email.blank? && (signed_in_with_invitation_token? || (notification_email && connected_with_sso?))
  end

  def notification_email_label = signed_in_with_invitation_token? ? "Email" : "Email de notification"
  def notification_email_required? = signed_in_with_invitation_token? && notification_email.present?

  def show_landline_phone_number_warning? = phone_number.present? && !phone_number_mobile?
  def show_caisse_affiliation_field? = territories.any?(&:enable_caisse_affiliation_field)
  def show_affiliation_number_field? = territories.any?(&:enable_affiliation_number_field)
  def show_logement_field? = territories.any?(&:enable_logement_field)
  def show_address_details_field? = territories.any?(&:enable_address_details)
end
