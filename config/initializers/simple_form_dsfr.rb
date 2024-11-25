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
