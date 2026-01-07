class Users::LoginCodesController < ApplicationController
  layout "application_narrow"

  include CanHaveRdvWizardContext

  def create
    email = params[:login_code][:email]
    if email && LoginCode.most_recent_usable_for(email:)&.very_recent?
      return redirect_to new_users_sessions_by_code_path(email:), flash: { notice: <<~NOTICE }
        Un code a été envoyé à #{email} il y a moins de deux minutes. Vous devriez recevoir ce code d’ici peu de temps.
      NOTICE
    end

    @login_code = LoginCode.new(email:, domain_id: current_domain.id)

    if @login_code.save
      Users::LoginCodeMailer.with(login_code: @login_code).login_code.deliver_later
      redirect_to new_users_sessions_by_code_path(email:)
    else
      render "users/sessions/new"
    end
  end

  private

  def storable_location? = false
end
