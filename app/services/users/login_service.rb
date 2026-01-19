class Users::LoginService
  attr_reader :email, :code, :controller

  def initialize(email:, code:, controller:)
    @email = email
    @code = code
    @controller = controller
  end

  def perform
    if matching_login_code&.usable?
      sign_in_user
      true
    else
      false
    end
  end

  def usable_login_code_exists?
    return @usable_login_code_exists if defined?(@usable_login_code_exists)

    @usable_login_code_exists = LoginCode.where(email:).usable.any?
  end

  def should_redirect_to_code_request? = !usable_login_code_exists?

  def error
    @error ||=
      if usable_login_code_exists?
        "Veuillez renseigner le dernier code qui vous a été envoyé par email, ou attendre quelques instants de le recevoir"
      elsif matching_login_code&.used?
        "Code déjà utilisé, veuillez en demander un nouveau"
      elsif matching_login_code&.expired?
        "Code expiré, veuillez en demander un nouveau"
      else
        "Code invalide"
      end
  end

  def matching_login_code
    @matching_login_code ||= LoginCode
      .where(email:, code: code)
      .where("created_at > ?", 24.hours.ago)
      .first
  end

  def user
    @user ||= User.find_by!(email:)
  end

  private

  def sign_in_user
    user.confirm
    controller.sign_in(:user, user)
    matching_login_code.update!(used_at: Time.zone.now)
  end
end
