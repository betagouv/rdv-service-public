class UpsertUserForFranceconnectService < BaseService
  attr_reader :user, :new_user, :omniauth_info
  alias new_user? new_user

  def initialize(omniauth_info)
    @omniauth_info = omniauth_info
  end

  def perform
    @user = User.find_by(franceconnect_openid_sub: omniauth_info.sub) \
      || User.find_by(email: omniauth_info.email)
    @new_user = @user.nil?
    if @user.nil?
      create_new_user
    elsif !@user.logged_once_with_franceconnect?
      update_existing_user
    end
    self
  end

  private

  def update_existing_user
    @user.update!(user_attribute_values_from_fc)
  end

  def create_new_user
    @user = User.new(
      user_attribute_values_from_fc.merge(
        email: omniauth_info.email,
        created_through: "franceconnect_sign_up"
      )
    )
    @user.skip_duplicate_warnings = true
    @user.skip_confirmation!
    @user.save!
    @user
  end

  def user_attribute_values_from_fc
    {
      first_name: omniauth_info.given_name,
      birth_name: omniauth_info.family_name, # nom de naissance
      birth_date: omniauth_info.birthdate,
      franceconnect_openid_sub: omniauth_info.sub,
      last_name: omniauth_info.preferred_username.presence || omniauth_info.family_name, # nom d'usage (optionnel),
      logged_once_with_franceconnect: true
    }.compact # do not fill with missing values
  end
end
