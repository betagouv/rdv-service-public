class UpsertUserForFranceconnectService < BaseService
  attr_reader :user, :new_user, :omniauth_info
  alias new_user? new_user

  def initialize(omniauth_info)
    @omniauth_info = omniauth_info
  end

  def perform
    @user = User.find_by(franceconnect_openid_sub: omniauth_info.sub)
    @new_user = @user.nil?
    if @user.nil?
      create_new_user
    else
      update_existing_user
    end
    self
  end

  private

  def update_existing_user
    @user.assign_attributes(user_attribute_values_from_fc)
    if @user.encrypted_password.blank?
      @user.notification_email = omniauth_info.email&.downcase
    end
    @user.save!(context: :france_connect_login)
  end

  def create_new_user
    @user = User.new(
      user_attribute_values_from_fc.merge(
        notification_email: omniauth_info.email&.downcase,
        created_through: "franceconnect_sign_up"
      )
    )
    @user.skip_confirmation!
    @user.save!(context: :france_connect_login)
    @user
  end

  def user_attribute_values_from_fc
    {
      first_name: omniauth_info.given_name,
      birth_name: omniauth_info.family_name, # nom de naissance
      birth_date: omniauth_info.birthdate,
      franceconnect_openid_sub: omniauth_info.sub,
      last_name: omniauth_info.preferred_username.presence || omniauth_info.family_name, # nom d'usage (optionnel),
      logged_once_with_franceconnect: true,
    }.compact # do not fill with missing values
  end
end
