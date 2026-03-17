class Users::LoginCodeValidator
  # dans ce service on distingue 2 LoginCodes :
  # - `usable` : moins de 30 minutes et pas utilisé, peut servir à se connecter
  # - `matching` : celui qui correspond au code saisi par l’usager et a moins de 24h

  def initialize(email:, code:)
    @email = email
    @code = code
  end

  def valid?
    matching_login_code&.usable?
  end

  def valid_login_code
    matching_login_code if valid?
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

    @usable_login_code_exists = LoginCode.where(email: @email).usable.any?
  end

  def should_redirect_to_code_request? = !usable_login_code_exists?

  private

  def matching_login_code
    @matching_login_code ||= LoginCode
      .where(email: @email, code: @code)
      .where("created_at > ?", 24.hours.ago)
      .first
  end
end
