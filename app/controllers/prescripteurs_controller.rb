# frozen_string_literal: true

class PrescripteursController < ApplicationController
  def sign_in
    parsed_uri = URI.parse(session[:user_return_to])
    parsed_params = Rack::Utils.parse_nested_query(parsed_uri.query).to_h.symbolize_keys
    session[:rdv_wizard_params] = parsed_params
    @rdv_wizard = UserRdvWizard::Step1.new(nil, session[:rdv_wizard_params])
  end

  def new_user
    @user_form = user_form_object
    @rdv_wizard = UserRdvWizard::Step1.new(nil, session[:rdv_wizard_params])
    @prescripteur_info = { full_name: "Alex Prescripteur" }
  end

  private

  def user_form_object
    Admin::UserForm.new(
      User.new,
      ignore_benign_errors: params.dig(:user, :ignore_benign_errors),
      view_locals: { current_organisation: nil }
    )
  end
end
