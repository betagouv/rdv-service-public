# Crée un lien symbolique vers les pictogrammes de la gem dsfr-assets.
# Ces fichiers SVG n’étant pas inclus dans les assets précompilés par Rails,
# on les sert donc statiquement via public/assets/artwork.
# Il s’agit d’une solution quick-win, car nous allons certainement nous passer de Sprockets à terme.

gem_spec = Gem.loaded_specs["dsfr-assets"]
return unless gem_spec

artwork_source = File.join(gem_spec.full_gem_path, "vendor/assets/stylesheets/artwork")
artwork_dest = Rails.public_path.join("assets/artwork")

if File.symlink?(artwork_dest) && File.readlink(artwork_dest) == artwork_source
  # do nothing
else
  FileUtils.mkdir_p(File.dirname(artwork_dest))
  FileUtils.rm_rf(artwork_dest)
  FileUtils.ln_s(artwork_source, artwork_dest)
end
