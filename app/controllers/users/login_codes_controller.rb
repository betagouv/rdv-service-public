class Users::LoginCodesController < ApplicationController
  layout "application_narrow"

  include CanHaveRdvBookingFormContext

  def create
    login_code = LoginCode.new(**login_code_permitted_params, domain_id: current_domain.id)
    @login_code_request_form = Users::LoginCodeRequestForm.new(login_code, behaviour: params[:behaviour])

    if @login_code_request_form.save
      Users::LoginCodeMailer.with(login_code: @login_code_request_form.login_code).login_code.deliver_later
      redirect_to new_users_sessions_by_code_path(email: @login_code_request_form.email)
    else
      render "users/sessions/new"
    end
  end

  private

  def storable_location? = false

  def login_code_permitted_params
    params.require(:login_code_request_form).permit(:email, :first_name, :last_name)
  end
end
