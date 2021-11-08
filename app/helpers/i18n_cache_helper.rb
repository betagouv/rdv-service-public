# frozen_string_literal: true

module I18nCacheHelper
  # Make the fragment cache locale-dependent,
  # and make sure to invalidate cache when the i18n dictionary changes.
  def cache(name = {}, options = {}, &block)
    name_with_locale = [name, locale_cache_key].flatten
    super(name_with_locale, options, &block)
  end

  # A cache key depending on the actual translations for the current locale
  def locale_cache_key
    if Rails.env.production?
      # In production, we’re sure the translations wont change until a restart
      @locale_cache_key ||= locale_translations_hash
    else
      # In development, we want to take live changes to the yml files into account.
      locale_translations_hash
    end
  end

  def locale_translations_hash
    I18n.backend.translations[I18n.locale].hash
  end
end
