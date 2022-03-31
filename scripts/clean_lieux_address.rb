# frozen_string_literal: true

# ce script permet de nettoyer toutes les adresses déjà existances de RDV-S. ref de l'issue: #2293
Lieu.where(cleaned_address: nil).find_each do |lieu|
  cleaned_address = Lieu.cleaned_old_addresse(lieu.address)
  lieu.update_column(:cleaned_address, cleaned_address) # rubocop:disable Rails/SkipsModelValidations
end
