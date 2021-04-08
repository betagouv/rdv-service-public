class DuplicateUsersFinderService < BaseService
  def initialize(user, organisation = nil)
    @user = user
    @organisation = organisation
  end

  def perform
    @duplicates = []
    check_email
    check_identity
    check_phone_number
    @duplicates
  end

  private

  attr_reader :user, :organisation

  def check_email
    return if user.email.blank?

    similar_user = users_in_scope.where(email: user.email).first
    return nil unless similar_user.present?

    @duplicates << OpenStruct.new(severity: :error, attributes: [:email], user: similar_user)
  end

  def check_identity
    return nil unless user.birth_date.present? && user.first_name.present? && user.last_name.present?

    similar_user = users_in_scope.where(
      first_name: user.first_name.capitalize,
      last_name: user.last_name.upcase,
      birth_date: user.birth_date
    ).first
    return nil unless similar_user.present?

    @duplicates << OpenStruct.new(severity: :error, attributes: [:first_name, :last_name, :birth_date], user: similar_user)
  end

  def check_phone_number
    return nil if user.phone_number_formatted.blank?

    similar_user = users_in_scope
      .where(phone_number_formatted: user.phone_number_formatted)
      .first
    return if similar_user.nil?

    @duplicates << OpenStruct.new(severity: :warning, attributes: [:phone_number], user: similar_user)
  end

  def users_in_scope
    u = User.active.left_joins(:rdvs).group(:id).order("COUNT(rdvs.id) DESC")
    u = u.where.not(id: user.id) if user.persisted?
    u = u.within_organisation(organisation) if organisation.present?
    u
  end
end
