# Crée un lien symbolique vers les pictogrammes de la gem dsfr-assets.
# Ces fichiers SVG utilisent des fragments (#artwork-decorative, etc.)
# et ne sont pas compatibles avec le fingerprinting Sprockets.
# On les sert donc statiquement via public/assets/artwork.

gem_spec = Gem.loaded_specs["dsfr-assets"]
return unless gem_spec

artwork_source = File.join(gem_spec.full_gem_path, "vendor/assets/stylesheets/artwork")
artwork_dest = Rails.public_path.join("assets/artwork")

if File.symlink?(artwork_dest)
  # Vérifie que le symlink pointe vers le bon endroit
  unless File.readlink(artwork_dest) == artwork_source
    FileUtils.rm(artwork_dest)
    FileUtils.ln_s(artwork_source, artwork_dest)
  end
elsif File.exist?(artwork_dest)
  # Si c'est un dossier/fichier réel, on le supprime et recrée le symlink
  FileUtils.rm_rf(artwork_dest)
  FileUtils.ln_s(artwork_source, artwork_dest)
else
  # Crée le dossier parent si nécessaire
  FileUtils.mkdir_p(File.dirname(artwork_dest))
  FileUtils.ln_s(artwork_source, artwork_dest)
end
