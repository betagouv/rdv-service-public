class Users::EmailChangeRequestsController < UserAuthController
  layout "application_base"

  before_action { authorize(current_user, :update?, policy_class: User::UserPolicy) }

  def new
    @email_change_request_form = Users::EmailChangeRequestForm.new(current_user:, domain_id: current_domain.id)
  end

  def create
    email = form_params[:email]
    @email_change_request_form = Users::EmailChangeRequestForm.new(email:, current_user:, domain_id: current_domain.id)

    if @email_change_request_form.save
      session[:user_new_email_pending_confirmation] = email
      # stocker l’email en session permet de supporter le refresh après soumission échouée du code de confirmation
      redirect_to new_email_change_confirmation_path(email:)
    else
      render :new
    end
  end

  private

  def form_params
    params.require(:email_change_request_form).permit(:email)
  end
end
