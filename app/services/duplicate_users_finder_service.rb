# frozen_string_literal: true

class DuplicateUsersFinderService < BaseService
  def initialize(user, organisation = nil)
    @user = user
    @organisation = organisation
  end

  def perform
    [
      self.class.find_duplicate_based_on_email(@user, @organisation),
      self.class.find_duplicate_based_on_identity(@user, @organisation),
      self.class.find_duplicate_based_on_phone_number(@user, @organisation)
    ].compact
  end

  class << self
    def find_duplicate_based_on_email(user, organisation)
      return if user.email.blank?

      similar_user = users_in_scope(user, organisation)
        .where(email: user.email).first
      return nil if similar_user.blank?

      OpenStruct.new(severity: :error, attributes: [:email], user: similar_user)
    end

    def find_duplicate_based_on_identity(user, organisation)
      return nil unless user.birth_date.present? && user.first_name.present? && user.last_name.present?

      similar_user = users_in_scope(user, organisation)
        .where(birth_date: user.birth_date)
        .where(User.arel_table[:first_name].matches(user.first_name))
        .where(User.arel_table[:last_name].matches(user.last_name)).first
      return nil if similar_user.blank?

      OpenStruct.new(severity: :warning, attributes: %i[first_name last_name birth_date], user: similar_user)
    end

    def find_duplicate_based_on_phone_number(user, organisation)
      return nil if user.phone_number_formatted.blank?

      similar_user = users_in_scope(user, organisation)
        .where(phone_number_formatted: user.phone_number_formatted)
        .first
      return if similar_user.nil?

      OpenStruct.new(severity: :warning, attributes: [:phone_number], user: similar_user)
    end

    def users_in_scope(user, organisation)
      u = User.active.left_joins(:rdvs).group(:id).order("COUNT(rdvs.id) DESC")
      u = u.where.not(id: user.id) if user.persisted?
      u = u.merge(organisation.users) if organisation.present?
      u
    end
  end
end
