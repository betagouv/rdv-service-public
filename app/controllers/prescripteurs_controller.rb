# frozen_string_literal: true

class PrescripteursController < ApplicationController
  def sign_in
    parsed_uri = URI.parse(session[:user_return_to])
    parsed_params = Rack::Utils.parse_nested_query(parsed_uri.query).to_h.symbolize_keys
    session[:rdv_wizard_params] = parsed_params
    @rdv_wizard = UserRdvWizard::Step1.new(nil, session[:rdv_wizard_params])
  end

  def new_user
    @user = User.new
    @rdv_wizard = UserRdvWizard::Step1.new(nil, session[:rdv_wizard_params])
    @user.user_profiles.build(organisation: current_organisation)
    @user_form = user_form_object
    @prescripteur_info = { full_name: "Alex Prescripteur" }
  end

  def confirmation
    redirect_to prescripteurs_done_path
  end

  def done; end

  def agent_user_form_url(_user)
    prescripteurs_confirmation_path
  end

  helper_method :current_organisation, :from_modal?, :current_territory, :agent_user_form_url

  def current_organisation
    @rdv_wizard.motif.organisation
  end

  def current_territory
    current_organisation.territory
  end

  def from_modal?
    false
  end

  private

  def user_form_object
    Admin::UserForm.new(
      @user,
      ignore_benign_errors: params.dig(:user, :ignore_benign_errors),
      view_locals: { current_organisation: Organisation.last }
    )
  end
end
