# frozen_string_literal: true

class DuplicateUsersFinderService

  def self.perform(user, organisation = nil)
    [
      find_duplicate_based_on_email(user, organisation),
      find_duplicate_based_on_identity(user, organisation),
      find_duplicate_based_on_phone_number(user, organisation)
    ].compact
  end

  private

  def self.find_duplicate_based_on_email(user, organisation)
    return if user.email.blank?

    similar_user = users_in_scope(user, organisation).where(email: user.email).first
    return nil if similar_user.blank?

    OpenStruct.new(severity: :error, attributes: [:email], user: similar_user)
  end

  def self.find_duplicate_based_on_identity(user, organisation)
    return nil unless user.birth_date.present? && user.first_name.present? && user.last_name.present?

    similar_user = users_in_scope(user, organisation).where(
      first_name: user.first_name.capitalize,
      last_name: user.last_name.upcase,
      birth_date: user.birth_date
    ).first
    return nil if similar_user.blank?

    OpenStruct.new(severity: :warning, attributes: %i[first_name last_name birth_date], user: similar_user)
  end

  def self.find_duplicate_based_on_phone_number(user, organisation)
    return nil if user.phone_number_formatted.blank?

    similar_user = users_in_scope(user, organisation)
      .where(phone_number_formatted: user.phone_number_formatted)
      .first
    return if similar_user.nil?

    OpenStruct.new(severity: :warning, attributes: [:phone_number], user: similar_user)
  end

  def self.users_in_scope(user, organisation)
    u = User.active.left_joins(:rdvs).group(:id).order("COUNT(rdvs.id) DESC")
    u = u.where.not(id: user.id) if user.persisted?
    u = u.within_organisation(organisation) if organisation.present?
    u
  end
end
