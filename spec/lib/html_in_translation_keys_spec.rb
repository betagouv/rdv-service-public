# frozen_string_literal: true

RSpec.describe "Avoid usage of html_safe on translation keys" do
  it "ne contient pas de clés de traduction qui n'utilise pas le suffixe _html mais qui contient du html" do
    I18n.backend.eager_load!

    # Un bricolage pour trouver les clés potentielles qui pourraint necessiter un html_safe
    translations_string = I18n.backend.translations[:fr].to_s
    translation_key_with_html_regex = /:[^=]*[^(_html)]=>"[^"]*<[^"]*>[^"]*"/

    regex_matches = translations_string.scan(translation_key_with_html_regex)
    if regex_matches.any?
      puts regex_matches
    end

    expect(regex_matches).to be_empty
  end
end
