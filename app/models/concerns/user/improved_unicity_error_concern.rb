# frozen_string_literal: true

module User::ImprovedUnicityErrorConcern
  extend ActiveSupport::Concern

  included do
    after_validation do
      email_taken_error = errors.where(:email, :taken).first
      next if email_taken_error.blank?

      email_taken_error.options[:id] = User.where.not(id: id).find_by(email: email).id
    end
  end
end
