# frozen_string_literal: true

module FullNameConcern
  extend ActiveSupport::Concern
  # Relies on the attributes of the receiver:
  # :first_name, :last_name, and :birth_name (optionally)

  # Marie Curie (Skłodowska)
  def full_name
    names = [first_name,
             last_name&.upcase,
             ("(#{birth_name})" if defined?(birth_name) && birth_name.present?),]

    names.compact.join(" ")
  end

  # Curie (Skłodowska) Marie
  def reverse_full_name
    names = [last_name&.upcase,
             ("(#{birth_name})" if defined?(birth_name) && birth_name.present?),
             first_name,]

    names.compact.join(" ")
  end

  # M. Curie
  def short_name
    "#{first_name.first.upcase}. #{last_name.upcase}"
  end
end
