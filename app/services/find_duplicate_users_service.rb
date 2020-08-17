class FindDuplicateUsersService < BaseService
  attr_reader :user

  SCORE_THRESHOLD = 0.8

  def initialize(user)
    @user = user
  end

  def perform
    result = []
    name1 = format_user_name(user)

    user.organisations.each do |organisation|
      organisation.users.where.not(id: user.id).each do |other_user|
        name2 = format_user_name(other_user)
        score = 1 - (DamerauLevenshtein.distance(name1, name2).to_f / [name1.length, name2.length].max)
        result << other_user if score >= SCORE_THRESHOLD
      end
    end
    result
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

