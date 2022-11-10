# frozen_string_literal: true

class DuplicateUsersFinderService < BaseService
  def initialize(user, organisation = nil)
    # TODO: Remove organisation from the parameters
    #   It is never used in the app. It’s only used when find_duplicate_based_on_phone_number is called directly.
    @user = user
    @organisation = organisation
  end

  def perform
    [
      self.class.find_duplicate_based_on_email(@user, @organisation),
      self.class.find_duplicate_based_on_identity(@user, @organisation),
      self.class.find_duplicate_based_on_phone_number(@user, @organisation),
    ].compact
  end

  class << self
    def find_duplicate_based_on_email(user, organisation)
      return if user.email.blank?

      duplicates = users_in_scope(user, organisation)
        .where(email: user.email)
      return unless duplicates.exists?

      OpenStruct.new(severity: :error, attributes: [:email], user: most_relevant_user(duplicates))
    end

    def find_duplicate_based_on_identity(user, organisation)
      return unless user.birth_date.present? && user.first_name.present? && user.last_name.present?

      duplicates = users_in_scope(user, organisation)
        .where(birth_date: user.birth_date) # index this
        .where(User.arel_table[:first_name].matches(user.first_name))
        .where(User.arel_table[:last_name].matches(user.last_name))
      return unless duplicates.exists?

      OpenStruct.new(severity: :warning, attributes: %i[first_name last_name birth_date], user: most_relevant_user(duplicates))
    end

    def find_duplicate_based_on_phone_number(user, organisation)
      return nil if user.phone_number_formatted.blank?

      duplicates = users_in_scope(user, organisation)
        .where(phone_number_formatted: user.phone_number_formatted)
      return unless duplicates.exists?

      OpenStruct.new(severity: :warning, attributes: [:phone_number], user: most_relevant_user(duplicates))
    end

    private

    def users_in_scope(user, organisation)
      u = User.all
      u = u.where.not(id: user.id) if user.persisted?
      u = u.merge(organisation.users) if organisation.present?
      u
    end

    def most_relevant_user(scope)
      # return the user with the most Rdvs.
      # Avoid doing it in users_in_scope because the join may be expensive.
      scope.left_joins(:rdvs).group(:id).order("COUNT(rdvs.id) DESC").first
    end
  end
end
