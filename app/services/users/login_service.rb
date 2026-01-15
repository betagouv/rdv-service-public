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

  def there_is_an_existing_and_usable_login_code?
    return @there_is_an_existing_and_usable_login_code if defined?(@there_is_an_existing_and_usable_login_code)

    @there_is_an_existing_and_usable_login_code = LoginCode.where(email:).usable.any?
  end

  def error
    @error ||=
      if there_is_an_existing_and_usable_login_code?
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
