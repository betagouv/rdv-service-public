class Users::ConfirmationsController < Devise::ConfirmationsController
  def create
    user = User.find_by_email(resource_params[:email])
    if user&.invitation_sent_at? && !user&.invitation_accepted?
      user.invite!
      flash[:notice] = I18n.t("devise.confirmations.send_instructions")
      return respond_with({}, location: after_resending_confirmation_instructions_path_for(resource_name))
    end

    super
  end
end
