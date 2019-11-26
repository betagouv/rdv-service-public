module FullNameConcern
  extend ActiveSupport::Concern

  def full_name
    "#{first_name} #{last_name}"
  end

  def short_name
    "#{first_name.first.upcase}. #{last_name}"
  end

  def initials
    full_name.split.first(2).map(&:first).join.upcase
  end
end
