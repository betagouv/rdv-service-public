Rails.application.config.after_initialize do
  next if !Rails.env.development? || !defined?(LetterOpenerWeb)

  LetterOpenerWeb::Letter.class_eval do
    alias_method :original_adjust_link_targets, :adjust_link_targets
    def adjust_link_targets(contents)
      original_adjust_link_targets(contents).gsub(".localhost/", ".localhost:3000/")
    end
  end

  # Nous appliquons des règles strictes au niveau de nos CSP, notamment sur l’exécution du JS.
  # Depuis la mise en place de ces règles Letter Opener ne fonctionne plus correctement, spécifiquement car il utilise du JS
  # inliné. Étant donné qu’il s’agit d’un outil utilisé uniquement en développement, on désactive les CSP dans son controller
  # pour ne pas perturber son fonctionnement.
  LetterOpenerWeb::ApplicationController.class_eval do
    content_security_policy false
  end
end
