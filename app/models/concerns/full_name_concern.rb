# frozen_string_literal: true

module FullNameConcern
  extend ActiveSupport::Concern

  def full_name
    f_n = [last_name]
    f_n << "(#{birth_name})" if defined?(birth_name) && birth_name.present?
    f_n << first_name
    f_n.join(" ")
  end

  def short_name
    "#{last_name} #{first_name.first.upcase}."
  end
end
