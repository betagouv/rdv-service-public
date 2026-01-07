class Users::LoginCodesController < ApplicationController
  layout "application_narrow"

  include CanHaveRdvWizardContext

  def create
    email = params[:demande_login_code_form][:email]

    @demande_login_code_form = Users::DemandeLoginCodeForm.new(LoginCode.new(email:, domain_id: current_domain.id))

    if @demande_login_code_form.save
      Users::LoginCodeMailer.with(login_code: @demande_login_code_form.login_code).login_code.deliver_later
      redirect_to new_users_sessions_by_code_path(email:)
    else
      render "users/sessions/new"
    end
  end

  private

  def storable_location? = false
end
