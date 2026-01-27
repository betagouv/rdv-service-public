class Users::LoginCodesController < ApplicationController
  layout "application_narrow"

  include CanHaveRdvWizardContext

  def create
    @login_code_request_form = Users::LoginCodeRequestForm.new(LoginCode.new(**permitted_params, domain_id: current_domain.id))

    if @login_code_request_form.save
      Users::LoginCodeMailer.with(login_code: @login_code_request_form.login_code).login_code.deliver_later
      redirect_to new_users_sessions_by_code_path(email: permitted_params[:email])
    else
      render "users/sessions/new"
    end
  end

  private

  def storable_location? = false

  def permitted_params
    params.require(:login_code_request_form).permit(:email, :first_name, :last_name)
  end
end
