module StrongPasswordConcern
  extend ActiveSupport::Concern

  included do
    validate :check_password_is_uncommon
    validate :password_complexity
  end

  protected

  def check_password_is_uncommon
    return true unless will_save_change_to_encrypted_password?

    if common_passwords.include?(password)
      errors.add(:password, :too_common)
    end
  end

  def common_passwords
    CommonFrenchPasswords.list.select { |p| p.length >= Devise.password_length.first }
  end

  def password_complexity
    # voir app/javascript/components/dsfr-new-password.js
    return if password.blank?

    unless password[/\d/]
      errors.add :password, "Votre mot de passe doit comporter au moins un chiffre."
    end

    if password.downcase == password
      errors.add :password, "Votre mot de passe doit comporter au moins une majuscule."
    end

    unless password[/[^A-Za-z0-9_]/]
      errors.add :password, "Votre mot de passe doit comporter au moins un caractère spécial, par exemple un signe de ponctuation."
    end
  end
end
