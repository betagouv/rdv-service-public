class DuplicateUsersFinderService < BaseService
  def initialize(candidate_user:, within_territory:)
    @candidate_user = candidate_user
    @scope = within_territory.users
  end

  def perform
    [
      self.class.find_duplicate_based_on_email(@candidate_user),
      self.class.find_duplicate_based_on_identity(@candidate_user, @scope),
      self.class.find_duplicate_based_on_phone_number(@candidate_user, @scope),
    ].compact
  end

  class << self
    def find_duplicate_based_on_email(candidate_user)
      return if candidate_user.email.blank?

      duplicates = User
        .where.not(id: candidate_user.id)
        .where(email: candidate_user.email)
      return unless duplicates.exists?

      OpenStruct.new(severity: :error, attributes: [:email], user: most_relevant_user(duplicates))
    end

    def find_duplicate_based_on_identity(candidate_user, scope)
      return unless candidate_user.birth_date.present? && candidate_user.first_name.present? && candidate_user.last_name.present?

      duplicates = scope
        .where.not(id: candidate_user.id)
        .where(birth_date: candidate_user.birth_date)
        .merge(match_on_names(candidate_user.first_name, candidate_user.last_name))
      return unless duplicates.exists?

      OpenStruct.new(severity: :warning, attributes: %i[first_name last_name birth_date], user: most_relevant_user(duplicates))
    end

    def find_duplicate_based_on_names_and_phone(candidate_user:, scope:)
      return unless candidate_user.phone_number_formatted.present? && candidate_user.first_name.present? && candidate_user.last_name.present?

      duplicates = scope
        .where.not(id: candidate_user.id)
        .where(phone_number_formatted: candidate_user.phone_number_formatted)
        .merge(match_on_names(candidate_user.first_name, candidate_user.last_name))
      return unless duplicates.exists?

      most_relevant_user(duplicates)
    end

    def find_duplicate_based_on_phone_number(candidate_user, scope)
      return nil if candidate_user.phone_number_formatted.blank?

      duplicates = scope
        .where.not(id: candidate_user.id)
        .where(phone_number_formatted: candidate_user.phone_number_formatted)
      return unless duplicates.exists?

      OpenStruct.new(severity: :warning, attributes: [:phone_number], user: most_relevant_user(duplicates))
    end

    private

    def match_on_names(first_name, last_name)
      User.where(
        "unaccent(lower(first_name)) = ?", I18n.transliterate(first_name.downcase.strip)
      ).where(
        "unaccent(lower(last_name)) = ?", I18n.transliterate(last_name.downcase.strip)
      )
    end

    def most_relevant_user(scope)
      # return the user with the most Rdvs.
      # For performance reasons, we only run that query once we determined that there is at least one duplicate.
      User.where(id: scope.ids).left_joins(:rdvs).group(:id).order("COUNT(rdvs.id) DESC").first
    end
  end
end
