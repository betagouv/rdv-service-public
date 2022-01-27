# frozen_string_literal: true

module TextSearch
  extend ActiveSupport::Concern
  # Full Text Search support, using pg_search.
  #
  # Models including this concern need to have:
  # * a :search_terms text attribute in database
  # * a :search_keys class method returning the names of the attributes to use for searching.
  # Additionally, :search_terms, and :email if used, should be indexed in the database.
  # The search_terms index looks like this:
  #   add_index :user, to_tsvector('simple'::regconfig, COALESCE(user.search_terms, ''::text)), using: :gin
  #
  # This module has three roles:
  # 1. Make sure the search terms are up-to-date when the model is saved
  # 2. Special case email search by using the :email column
  #   This is needed to search for partial emails,
  #   e.g. when searching "john.doe@example" should return the row containing "john.doe@example.com".
  #   That wouldn't work with PG text search because PG actually parses the text token, and a valid email is
  #   saved as one token ("john.doe@example.com”") while an invalid email is several tokens ("john.doe", "@", "example")
  #   See https://www.postgresql.org/docs/current/textsearch-parsers.html
  #   If the search term looks like an email, we search on email only.
  #   We can't combine the query with search_on_search_terms as it would lose the text ranking.
  # 3. Special case phone number search by normalizing the phone number
  #   We store phone numbers in e164 form.
  #   When searching "01 23 45 67", we want to return the row containing "+33123456789".

  included do
    include PgSearch::Model

    pg_search_scope(:search_on_search_terms, against: :search_terms, using: { tsearch: { prefix: true, any_word: true } })

    before_save :refresh_search_terms
  end

  class_methods do
    def search_by_text(term)
      term = clean_search_term(term)
      return none if term.blank?

      if search_keys.include?(:email) && looks_like_email(term)
        where("email LIKE ?", "#{term}%")
      else
        search_on_search_terms(term)
      end
    end

    def clean_search_term(term)
      return if term.blank?

      if looks_like_phone_number(term)
        term.sub(/^0/, "+33").gsub(/\s/, "")
      else
        I18n.transliterate(term)
      end
    end

    def looks_like_email(string)
      /^.*@.*$/.match?(string)
    end

    def looks_like_phone_number(string)
      /^(\+\d{2})?[\d ]{3,20}$/.match?(string)
    end
  end

  def refresh_search_terms
    self.search_terms = combined_search_terms
  end

  def combined_search_terms
    keys = self.class.search_keys.map(&:to_s)
    terms = attributes.slice(*keys).values
    I18n.transliterate(terms.compact.join(" "))
  end
end
