class Users::LoginService
  # dans ce service on distingue 2 LoginCodes :
  # - `usable` : moins de 30 minutes et pas utilisé, peut servir à se connecter
  # - `matching` : celui qui correspond au code saisi par l’usager et a moins de 24h

  attr_reader :email, :code, :sign_in_user_lambda, :user

  delegate :first_name, :last_name, to: :matching_login_code

  def initialize(email:, code:, sign_in_user_lambda:)
    @email = email
    @code = code
    @sign_in_user_lambda = sign_in_user_lambda
  end

  def perform
    if matching_login_code&.usable?
      @user = upsert_user
      user.update!(latest_login_at: Time.zone.now)
      sign_in_user_lambda.call(user)
      matching_login_code.update!(used_at: Time.zone.now)
      true
    else
      false
    end
  end

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

  def usable_login_code_exists?
    return @usable_login_code_exists if defined?(@usable_login_code_exists)

    @usable_login_code_exists = LoginCode.where(email:).usable.any?
  end

  def should_redirect_to_code_request? = !usable_login_code_exists?

  private

  def matching_login_code
    @matching_login_code ||= LoginCode
      .where(email:, code: code)
      .where("created_at > ?", 24.hours.ago)
      .first
  end

  def upsert_user
    user = User.joins(:rdvs).order("rdvs.created_at DESC, users.created_at DESC").where(email: email).first
    if user
      update_user(user) if first_name.present? && last_name.present?
    else
      user = create_user
    end
    user
  end

  def update_user(user)
    if (user.first_name != first_name || user.last_name != last_name) &&
       !user.logged_once_with_franceconnect? # les users FranceConnectés ne peuvent pas modifier leur identité
      user.update!(first_name: first_name, last_name: last_name)
    end
  end

  def create_user
    User.create!(email:, first_name:, last_name:, created_through: "auto_through_login")
  end
end
