class Users::UserNameInitialsVerificationController < UserAuthController
  skip_after_action :verify_authorized

  include TokenInvitable

  def new
    @form = Form.new
  end

  def create
    @form = Form.new(letters: params[:letters]&.strip&.upcase, current_user:)
    if @form.valid?
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

  class Form
    include ActiveModel::Model
    include ActiveModel::Attributes
    attribute :letters, :string
    attribute :current_user

    validate :letters_match_last_name

    def letters_match_last_name
      return if letters == current_user.last_name.gsub(/\s+/, "").first(3).upcase

      errors.add(:letters, "ne correspondent pas")
    end

    def self.human_attribute_name(attr, _options = {})
      if attr.to_sym == :letters
        "3 premières lettres"
      else
        attr
      end
    end
  end
end
