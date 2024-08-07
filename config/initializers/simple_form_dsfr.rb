# Configuration SimpleForm pour le dsfr
SimpleForm.setup do |config|
  config.wrappers :dsfr_wrapper, tag: "div" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: "fr-label"
    b.use :input, class: "fr-input"
    b.use :full_error, wrap_with: { tag: "p", class: "fr-error-text" }
    b.use :hint
  end
end

# L’initializer simple_form_bootstrap.rb est lu par défaut pour toutes les parties de l’application
# Or, nous souhaitons migrer pas à pas une partie de l’application vers le DSFR
# Ce concern peut être inclus dans un contrôleur et overrider la configuration spécifique bootstrap
# uniquement pour les actions de ce contrôleur.

module SimpleFormDsfrConcern
  extend ActiveSupport::Concern

  included do
    around_action :override_simple_form_config
  end

  def override_simple_form_config
    button_class_before = SimpleForm.button_class
    SimpleForm.button_class = "fr-btn"
    yield
  ensure
    SimpleForm.button_class = button_class_before
  end
end
