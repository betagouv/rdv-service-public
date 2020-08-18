class MarkFirstPotentialDuplicateService < BaseService
  attr_reader :user

  SCORE_THRESHOLD = 0.8

  def initialize(user)
    @user = user
  end

  def perform
    mark first_duplicate
  end

  def first_duplicate
    user.organisations.each do |organisation|
      organisation.users.where.not(id: user.id).each do |other_user|
        return other_user if names_are_close?(user, other_user)
      end
    end
    nil
  end

  def names_are_close?(user, other_user)
    score(user, other_user) >= SCORE_THRESHOLD
  end

  def score(user, other_user)
    name1 = format_user_name(user)
    name2 = format_user_name(other_user)
    1 - (DamerauLevenshtein.distance(name1, name2).to_f / [name1.length, name2.length].max)
  end

  def mark(duplicate)
    user.update!(potential_duplicate: duplicate)
    duplicate
  end

  private

  def format_user_name(user)
    "#{user.first_name} #{user.last_name}"
      .parameterize
      .gsub(/(monsieur\-|madame\-|mr\-|mme\-|m\-|mlle\-)/, "")
      .gsub("-", " ")
      .strip
  end
end
