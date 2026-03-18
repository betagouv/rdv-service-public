module Users::UserFormConcern
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model

    attr_reader :user, :domain

    delegate :first_name, :last_name, :birth_name, :birth_date,
             :phone_number, :phone_number_mobile?,
             :email, :email_changed?,
             :address, :address_details, :city_code, :post_code, :city_name,
             :caisse_affiliation, :affiliation_number, :logement,
             :notify_by_email, :notify_by_sms,
             :connected_with_sso?, :pro_connect_openid_sub,
             :logged_once_with_franceconnect?, :signed_in_with_invitation_token?,
             :errors, :errors_are_all_benign?, :benign_errors,
             :ants_pre_demande_number,
             to: :user

    def self.human_attribute_name(...) = User.human_attribute_name(...)
  end

  def show_birth_name_field?
    !signed_in_with_invitation_token? && domain != Domain::RDV_SERVICE_PUBLIC && !pro_connect_openid_sub
  end

  def birth_name_frozen? = connected_with_sso?

  def first_name_frozen? = connected_with_sso?

  def last_name_frozen? = pro_connect_openid_sub.present?

  def birth_date_frozen? = logged_once_with_franceconnect?

  def show_franceconnect_frozen_fields_warning? = logged_once_with_franceconnect?

  # NOTE: à discuter en équipe
  # Ancien fonctionnement : email (Devise) affiché disabled pour les invités qui en avaient un.
  # notification_email affiché modifiable pour les invités sans email et les usagers SSO.
  # Comportement actuel :
  # - Invité avec email → affiché, disabled
  # - Invité sans email → affiché, modifiable, non requis
  # - SSO (FC/ProConnect) → affiché, modifiable, non requis
  # - Usager normal → pas affiché
  def show_email_field? = signed_in_with_invitation_token? || connected_with_sso?

  def email_disabled? = signed_in_with_invitation_token? && email.present?

  def show_landline_phone_number_warning? = phone_number.present? && !phone_number_mobile?

  def user_profiles_territories
    @user_profiles_territories ||= Territory.joins(organisations: :user_profiles).where(user_profiles: { user_id: user.id }).to_a
  end

  def show_caisse_affiliation_field? = user_profiles_territories.any?(&:enable_caisse_affiliation_field)

  def show_affiliation_number_field? = user_profiles_territories.any?(&:enable_affiliation_number_field)

  def show_address_details_field? = user_profiles_territories.any?(&:enable_address_details)
end
