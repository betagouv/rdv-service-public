# frozen_string_literal: true

class ExternalInvitations::BaseController < ApplicationController
  before_action :store_invitation_token_in_session_if_present
  before_action :set_variables_from_invitation
  before_action :redirect_if_invitation_invalid
  before_action :redirect_if_invited_user_is_not_current_user
  before_action :redirect_if_user_does_not_belong_to_org

  PERMITTED_PARAMS = %i[departement where latitude longitude city_code street_ban_id invitation_token].freeze

  private

  def redirect_if_invitation_invalid
    return if invited_user.present?

    flash[:error] = t("devise.invitations.invitation_token_invalid")
    redirect_to root_path
  end

  def redirect_if_invited_user_is_not_current_user
    return if current_user.blank?
    return if current_user == invited_user

    flash[:error] = t("devise.invitations.current_user_mismatch")
    redirect_to root_path
  end

  def redirect_if_user_does_not_belong_to_org
    return if invited_user.organisation_ids.include?(@organisation.id)

    flash[:error] = t("devise.invitations.organisation_mismatch")
    redirect_to root_path
  end

  def invited_user
    # rubocop:disable Rails/DynamicFindBy
    # find_by_invitation_token is a method added by the devise_invitable gem
    @invited_user ||= User.find_by_invitation_token(@invitation_token, true)
    # rubocop:enable Rails/DynamicFindBy
  end

  def invitation_params
    params.permit(*PERMITTED_PARAMS)
  end

  def set_variables_from_invitation
    @query = invitation_params.to_h
    @invitation_token = params[:invitation_token]
    @latitude = invitation_params[:latitude]
    @longitude = invitation_params[:longitude]
    @where = invitation_params[:where]
    @city_code = invitation_params[:city_code]
    @departement = invitation_params[:departement]
    @street_ban_id = invitation_params[:street_ban_id]
    @organisation = Organisation.find(params[:organisation_id])
    @service = Service.find(params[:service_id])
    @geo_search = Users::GeoSearch.new(departement: @departement, city_code: @city_code, street_ban_id: @street_ban_id)
  end
end
