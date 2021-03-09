module User::ImprovedUnicityErrorConcern
  extend ActiveSupport::Concern

  included do
    after_validation do
      email_taken_error = errors.details[:email]&.select { _1[:error] == :taken }&.first
      next if email_taken_error.blank?

      email_taken_error["id"] = User.where.not(id: id).find_by(email: email).id
    end
  end
end
