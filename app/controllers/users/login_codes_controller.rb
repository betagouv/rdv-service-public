class Users::LoginCodesController < ApplicationController
  layout "application_narrow"

  include CanHaveRdvWizardContext

  def create
    email = params[:login_code_form_request][:email]

    @login_code_form_request = Users::LoginCodeRequestForm.new(LoginCode.new(email:, domain_id: current_domain.id))

    if @login_code_form_request.save
      Users::LoginCodeMailer.with(login_code: @login_code_form_request.login_code).login_code.deliver_later
      redirect_to new_users_sessions_by_code_path(email:)
    else
      render "users/sessions/new"
    end
  end

  private

  def storable_location? = false
end
