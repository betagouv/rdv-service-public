Apipie.configure do |config|
  config.app_name                = "Lapin"
  config.api_base_url            = "/api"
  config.doc_base_url            = "/apipie"
  config.languages = ['fr']
  config.default_locale = 'fr'
  config.locale = lambda { |loc| loc ? I18n.locale = loc : I18n.locale }
  config.translate = lambda do |str, loc|
    return '' if str.blank?
    I18n.t str, locale: loc, scope: 'doc'
  end
  # where is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/**/*.rb"
end
