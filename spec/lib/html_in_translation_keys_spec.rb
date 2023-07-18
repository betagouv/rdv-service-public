# frozen_string_literal: true

RSpec.describe "Avoid usage of html_safe on translation keys" do
  specify do
    I18n.backend.eager_load!
    translations_json = I18n.backend.translations.to_json
    translation_key_with_html_regex = /".*":".*<.*>.*"/

    regex_matches = translation_key_with_html_regex.match(translations_json)

    byebug
  end
end
