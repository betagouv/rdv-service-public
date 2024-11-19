# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules")
Rails.application.config.assets.css_compressor = nil # css compressor is done with webpack

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

# See https://github.com/rails/sprockets/issues/581
Rails.application.config.assets.configure do |env|
  env.export_concurrent = false
end

if Rake::Task.task_defined?("assets:precompile") # la tâche n’est définie que dans le contexte de précompilation
  Rake::Task["assets:precompile"].enhance do
    # copy favicon
    FileUtils.cp_r Rails.root.join("app/assets/images/favicon/favicon.ico"), Rails.public_path.join("favicon.ico")
    Rails.logger.info "✅ favicon.ico copied"

    # DSFR fonts and icons are copied to the root public folder whereas artwork is copied to a public/dsfr/ dir
    FileUtils.cp_r Rails.root.join("node_modules/@gouvfr/dsfr/dist/fonts"), Rails.public_path
    FileUtils.cp_r Rails.root.join("node_modules/@gouvfr/dsfr/dist/icons"), Rails.public_path
    Rails.public_path.join("dsfr").mkdir
    FileUtils.cp_r Rails.root.join("node_modules/@gouvfr/dsfr/dist/artwork"), Rails.public_path.join("dsfr/artwork")
    Rails.logger.info "✅ DSFR assets copied"
  end
end
