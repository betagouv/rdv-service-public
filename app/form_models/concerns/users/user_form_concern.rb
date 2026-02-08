module Users::UserFormConcern
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Model

    attr_reader :user, :domain

    delegate :first_name, :last_name, :birth_name, :birth_date,
             :phone_number, :phone_number_mobile?,
             :email, :email_changed?, :notification_email,
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
end
