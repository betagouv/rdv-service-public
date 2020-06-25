class FranceConnectController < ApplicationController
  include FranceConnect::Utils

  # before_action :redirect_to_login_if_fc_aborted, only: [:callback]

  def login
    redirect_to france_connect_authorization_uri
  end

  def callback
    @user_infos = france_connect_retrieve_user_infos(params[:code])

    # if fci.user.nil?
    #   user = User.find_or_create_by!(email: fci.email_france_connect.downcase) do |new_user|
    #     new_user.password = Devise.friendly_token[0, 20]
    #     new_user.confirmed_at = Time.zone.now
    #   end

    #   fci.update_attribute('user_id', user.id)
    # end

    # connect_france_connect_particulier(fci.user)
  rescue Rack::OAuth2::Client::Error => e
    Rails.logger.error e.message
    redirect_france_connect_error_connection
  end

  private

  # def redirect_to_login_if_fc_aborted
  #   if params[:code].blank?
  #     redirect_to new_user_session_path
  #   end
  # end

  def connect_france_connect_particulier(user)
    sign_out :user if user_signed_in?
    sign_out :agent if agent_signed_in?

    sign_in user

    # user.update_attribute('loged_in_with_france_connect', User.loged_in_with_france_connects.fetch(:particulier))

    redirect_to stored_location_for(current_user) || root_path(current_user)
  end

  def redirect_france_connect_error_connection
    flash.alert = t('errors.messages.france_connect.connexion')
    redirect_to(new_user_session_path)
  end
end
