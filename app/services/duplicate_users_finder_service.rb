# frozen_string_literal: true

class DuplicateUsersFinderService
  def self.perform(user, organisation = nil)
    similar_users = users_in_scope(user, organisation)
    [
      find_duplicate_based_on_email(user, similar_users),
      find_duplicate_based_on_identity(user, similar_users),
      find_duplicate_based_on_phone_number(user, similar_users)
    ].compact
  end

  def self.find_duplicate_based_on_email(user, similar_users)
    return if user.email.blank?

    similar_user = similar_users.where(email: user.email).first
    return nil if similar_user.blank?

    OpenStruct.new(severity: :error, attributes: [:email], user: similar_user)
  end

  def self.find_duplicate_based_on_identity(user, similar_users)
    return nil unless user.birth_date.present? && user.first_name.present? && user.last_name.present?

    similar_user = similar_users.where(
      first_name: user.first_name.capitalize,
      last_name: user.last_name.upcase,
      birth_date: user.birth_date
    ).first
    return nil if similar_user.blank?

    OpenStruct.new(severity: :warning, attributes: %i[first_name last_name birth_date], user: similar_user)
  end

  def self.find_duplicate_based_on_phone_number(user, similar_users)
    return nil if user.phone_number_formatted.blank?

    similar_user = similar_users
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
