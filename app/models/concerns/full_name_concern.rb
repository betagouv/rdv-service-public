# frozen_string_literal: true

module FullNameConcern
  extend ActiveSupport::Concern

  def full_name
    f_n = "#{first_name} #{last_name}"
    f_n += " (#{birth_name})" if defined?(birth_name) && birth_name.present?
    f_n
  end

  def short_name
    "#{first_name.first.upcase}. #{last_name}"
  end

  def initials
    full_name.split.first(2).map(&:first).join.upcase
  end
end
