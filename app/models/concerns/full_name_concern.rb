module FullNameConcern
  extend ActiveSupport::Concern
  # Relies on the attributes of the receiver:
  # :first_name, :last_name, and :birth_name (optionally)

  included do
    scope :ordered_by_last_name, -> { order(Arel.sql("unaccent(LOWER(#{table_name}.last_name))")) }
  end

  # Marie Curie (Skłodowska)
  def full_name
    names = [first_name,
             last_name&.upcase,
             ("(#{birth_name})" if show_birth_name?),]

    names.compact.join(" ")
  end

  # Curie (Skłodowska) Marie
  def reverse_full_name
    names = [last_name&.upcase,
             ("(#{birth_name})" if show_birth_name?),
             first_name,]

    names.compact.join(" ")
  end

  # M. Curie
  def short_name
    if first_name.present?
      "#{first_name.first.upcase}. #{last_name.upcase}"
    else
      last_name
    end
  end

  private

  def show_birth_name?
    defined?(birth_name) && birth_name.present? && birth_name&.upcase != last_name&.upcase
  end
end
