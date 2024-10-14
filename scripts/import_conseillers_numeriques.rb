# Usage:
# - télécharger l'export "Liste des candidats embauchés" (embauches.csv)
#   depuis https://pilotage.conseiller-numerique.gouv.fr/admin/exports
# - mettre le fichier embauches.csv dans tmp
# - exécuter: scalingo --app=production-rdv-solidarites --region=osc-secnum-fr1 run --file=tmp/embauches.csv "rails runner scripts/import_conseillers_numeriques.rb"

require "csv"

conseillers_numeriques = CSV.read("/tmp/uploads/embauches.csv", headers: true, col_sep: ";", liberal_parsing: true)

conseillers_numeriques.each do |conseiller_numerique|
  next if conseiller_numerique["email professionnel secondaire"].blank? || conseiller_numerique["Compte activé"]&.strip != "oui"

  external_id = "conseiller-numerique-#{conseiller_numerique['ID conseiller']}"

  agent = Agent.find_by(external_id: external_id)
  next if agent&.deleted_at?

  Sentry.with_scope do |scope|
    processed_params = {
      external_id: external_id,
      email: conseiller_numerique["email professionnel secondaire"],
      secondary_email: conseiller_numerique["email"],
      old_email: conseiller_numerique["email professionnel"],
      first_name: conseiller_numerique["prenom"],
      last_name: conseiller_numerique["nom"],
      structure: {
        external_id: conseiller_numerique["ID long Structure"],
        name: conseiller_numerique["Dénomination"],
        address: conseiller_numerique["Adresse de la structure"],
      },
    }.with_indifferent_access

    scope.set_context("Import CNFS", { processed_params: processed_params })

    AddConseillerNumerique.process!(processed_params)
  rescue StandardError => e
    Sentry.capture_exception(e)
  end
end
