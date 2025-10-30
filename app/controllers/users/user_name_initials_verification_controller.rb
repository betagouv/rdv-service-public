class Users::UserNameInitialsVerificationController < UserAuthController
  class Form
    include ActiveModel::Model
    include ActiveModel::Attributes # lets us declare attributes easily
    attribute :letters, :string
  end

  layout "application_narrow"

  skip_after_action :verify_authorized

  include TokenInvitable

  def new
    @form = Form.new
  end

  def create
    @form = Form.new(letters: params[:letters]&.strip&.upcase)
    if @form.letters == current_user.last_name.gsub(/\s+/, "").first(3).upcase
      set_user_name_initials_verified
      redirect_to after_success_redirect_path
    else
      flash.now[:error] = I18n.t("users.user_name_initials_mismatch")
      render :new
    end
  end

  private

  def after_success_redirect_path
    if session[:return_to_after_verification]
      session.delete(:return_to_after_verification)
    elsif invitation&.rdv
      users_rdv_path(invitation.rdv)
    else
      root_path
    end
  end
end
