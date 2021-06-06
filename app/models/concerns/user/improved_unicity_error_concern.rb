# frozen_string_literal: true

module User::ImprovedUnicityErrorConcern
  extend ActiveSupport::Concern

  included do
    after_validation do
      next unless errors.details.include?(:email) # The details Hash implicitely creates values when accessed, let’s avoid that.

      email_taken_error = errors.details[:email].select { _1[:error] == :taken }&.first
      next if email_taken_error.blank?

      email_taken_error["id"] = User.where.not(id: id).find_by(email: email).id
    end
  end
end
