# Par défaut, Rails ajoute une div avec une classe CSS "field_with_errors" aux champs de formulaire qui contiennent
# des erreurs. Nous n’utilisons pas cette classe CSS dans notre design, et l’ajout de cette div rentre en conflit avec
# certains éléments du DSFR. Nous désactivons ce comportement avec le code suivant.
ActionView::Base.field_error_proc = proc { |html_tag, _| html_tag }
