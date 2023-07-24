# frozen_string_literal: true

module StrongPasswordConcern
  extend ActiveSupport::Concern

  MIN_PASSWORD_LENGTH = 10

  included do
    validate :check_password_is_uncommon
  end

  protected

  def check_password_is_uncommon
    return true unless will_save_change_to_encrypted_password?

    if common_passwords.include?(password)
      errors.add(:password, :too_common)
    end
  end

  def common_passwords
    CommonFrenchPasswords.list.select { |p| p.length >= MIN_PASSWORD_LENGTH }
  end
end
