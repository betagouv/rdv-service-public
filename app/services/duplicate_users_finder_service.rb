# frozen_string_literal: true

class DuplicateUsersFinderService
  def self.find_duplicate_based_on_email(user)
    user = user.responsible&.new_record? ? user.responsible : user
    return if user.email.blank?

    users_in_scope(user).where(email: user.email).first
  end

  def self.find_duplicate(user)
    user = user.responsible&.new_record? ? user.responsible : user
    [
      find_duplicate_based_on_identity(user),
      find_duplicate_based_on_phone_number(user)
    ].compact.uniq
  end

  def self.find_duplicate_based_on_identity(user)
    return nil unless user.birth_date.present? && user.first_name.present? && user.last_name.present?

    users_in_scope(user).where(
      first_name: user.first_name.capitalize,
      last_name: user.last_name.upcase,
      birth_date: user.birth_date
    ).first
  end

  def self.find_duplicate_based_on_phone_number(user, organisation = nil)
    return nil if user.phone_number_formatted.blank?

    scoped_users = users_in_scope(user)
    scoped_users = scoped_users.within_organisation(organisation) if organisation.present?
    scoped_users
      .where(phone_number_formatted: user.phone_number_formatted)
      .first
  end

  def self.users_in_scope(user)
    u = User.active.left_joins(:rdvs).group(:id).order("COUNT(rdvs.id) DESC")
    u = u.where.not(id: user.id) if user.persisted?
    u
  end
end
