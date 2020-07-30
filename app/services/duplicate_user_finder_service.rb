class DuplicateUserFinderService < BaseService
  attr_reader :user

  def initialize(user, skip_warnings: false)
    @user = user
    @skip_warnings = skip_warnings
  end

  def perform
    check_email || check_identity || (check_phone_number unless @skip_warnings) || nil
  end

  private

  def check_email
    similar_user = users_in_scope.where.not(email: nil).find_by(email: @user.email)
    return nil unless similar_user.present?

    OpenStruct.new(severity: :error, attributes: [:email], user: similar_user)
  end

  def check_identity
    return nil unless @user.birth_date.present? && @user.first_name.present? && @user.last_name.present?

    similar_user = users_in_scope.where(
      first_name: @user.first_name.capitalize,
      last_name: @user.last_name.upcase,
      birth_date: @user.birth_date
    ).left_joins(:rdvs).group(:id).order("COUNT(rdvs.id) DESC").first
    return nil unless similar_user.present?

    OpenStruct.new(severity: :error, attributes: [:first_name, :last_name, :birth_date], user: similar_user)
  end

  def check_phone_number
    return nil unless @user.phone_number.present?

    similar_user = users_in_scope.where(phone_number: @user.phone_number).left_joins(:rdvs).group(:id).order("COUNT(rdvs.id) DESC").first
    return nil unless similar_user.present?

    OpenStruct.new(severity: :warning, attributes: [:phone_number], user: similar_user)
  end

  def users_in_scope
    User.active
  end
end
