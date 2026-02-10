class DuplicateUsersFinderService < BaseService
  def initialize(user:, organisations:)
    @user = user
    @organisations = organisations
  end

  def perform
    [
      self.class.find_duplicate_based_on_email(user: @user),
      self.class.find_duplicate_based_on_identity(user: @user, organisations: @organisations),
      self.class.find_duplicate_based_on_phone_number(user: @user, organisations: @organisations),
    ].compact
  end

  class << self
    def find_duplicate_based_on_email(user:)
      return if user.email.blank?

      duplicates = other_users(than: user)
        .where(email: user.email)
      return unless duplicates.exists?

      OpenStruct.new(severity: :error, attributes: [:email], user: most_relevant_user(duplicates))
    end

    def find_duplicate_based_on_identity(user:, organisations:)
      return unless user.birth_date.present? && user.first_name.present? && user.last_name.present?

      duplicates = other_users(than: user)
        .in_orgs(organisations)
        .where(birth_date: user.birth_date)
        .merge(match_on_names(user.first_name, user.last_name))
      return unless duplicates.exists?

      OpenStruct.new(severity: :warning, attributes: %i[first_name last_name birth_date], user: most_relevant_user(duplicates))
    end

    def find_duplicate_based_on_names_and_phone(user:, organisation:)
      return unless user.phone_number_formatted.present? && user.first_name.present? && user.last_name.present?

      duplicates = other_users(than: user)
        .in_orgs([organisation])
        .where(phone_number_formatted: user.phone_number_formatted)
        .merge(match_on_names(user.first_name, user.last_name))
      return unless duplicates.exists?

      most_relevant_user(duplicates)
    end

    def find_duplicate_based_on_phone_number(user:, organisations:)
      return nil if user.phone_number_formatted.blank?

      duplicates = other_users(than: user)
        .in_orgs(organisations)
        .where(phone_number_formatted: user.phone_number_formatted)
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

    def other_users(than:)
      u = User.all
      u = u.where.not(id: than.id) if than.persisted?
      u
    end

    def most_relevant_user(scope)
      # return the user with the most Rdvs.
      # Avoid doing it in users_in_scope because the join may be expensive.
      scope.left_joins(:rdvs).group(:id).order("COUNT(rdvs.id) DESC").first
    end
  end
end
