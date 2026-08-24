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
      build_new_user
    else
      set_email_on_existing_user
    end
    @user.assign_attributes(user_attribute_values_from_fc)
    @user.save!(context: :france_connect_login)

    save_ami_france_connect_hash if Ami.enabled?

    self
  end

  private

  def set_email_on_existing_user
    email_from_fc = omniauth_info.email.presence
    @user.email = email_from_fc if email_from_fc
  end

  def build_new_user
    @user = User.new(
      created_through: "franceconnect_sign_up",
      email: omniauth_info.email
    )
  end

  def user_attribute_values_from_fc
    {
      first_name: omniauth_info.given_name,
      birth_name: omniauth_info.family_name, # nom de naissance
      birth_date: omniauth_info.birthdate,
      franceconnect_openid_sub: omniauth_info.sub,
      last_name: omniauth_info.preferred_username.presence || omniauth_info.family_name, # nom d'usage (optionnel),
      logged_once_with_franceconnect: true,
      latest_login_at: Time.zone.now,
    }.compact # do not fill with missing values
  end

  def save_ami_france_connect_hash(omniauth_info)
    AmiFranceConnectHash.find_or_initialize_by(user_id: @user.id).update(fc_hash: ami_france_connect_hash(omniauth_info))
  end

  def ami_france_connect_hash(omniauth_info)
    attributes = [
      omniauth_info.given_name,
      omniauth_info.family_name,
      omniauth_info.birthdate,
      omniauth_info.gender,
      omniauth_info.birthplace,
      omniauth_info.birthcountry,
    ]

    Digest::SHA256.hexdigest(attributes.join)
  end
end
