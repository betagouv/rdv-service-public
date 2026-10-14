class NormalizeOrganisationWebsites < ActiveRecord::Migration[8.0]
  WHODUNNIT = "[Migration] NormalizeOrganisationWebsites".freeze

  def up
    Organisation.where.not(website: [nil, ""]).find_each do |organisation|
      next if Organisation.valid_website_url?(organisation.website)

      candidate = "https://#{organisation.website}"
      next unless Organisation.valid_website_url?(candidate)

      # sécurités supplémentaires
      next if URI.parse(candidate).host.exclude?(".") || # au moins un TLD
              candidate.length < 13 || # https:// + 5 chars
              candidate.include?("@")

      Rails.logger.info "updating orga #{organisation.name} website \n  from #{organisation.website}\n  to  \n  #{candidate}\n"
      organisation.skip_webhooks = true
      organisation.website = candidate
      PaperTrail.request(whodunnit: WHODUNNIT) { organisation.save(validate: false) }
    end
  end

  # Data fix : le down ne restaure pas les valeurs d'origine, il permet juste de
  # retirer la migration de schema_migrations (ex. pour la rejouer en local sur un dump).
  def down; end
end
