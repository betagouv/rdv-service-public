# frozen_string_literal: true

require "csv"

conseillers_numeriques = CSV.read("/tmp/uploads/export-cnfs.csv", headers: true, col_sep: ";")

conseillers_numeriques.each do |conseiller_numerique|
  next if conseiller_numerique["Email @conseiller-numerique.fr"].blank?

  external_id = "conseiller-numerique-#{conseiller_numerique['Id du conseiller']}"

  agent = Agent.find_by(external_id: external_id)
  next if agent&.deleted_at?

  agent = AddConseillerNumerique.process!({
    external_id: external_id,
    email: conseiller_numerique["Email @conseiller-numerique.fr"],
    alternate_email: conseiller_numerique["Email"],
    first_name: conseiller_numerique["Prénom"],
    last_name: conseiller_numerique["Nom"],
    structure: {
      external_id: conseiller_numerique["Id de la structure"],
      name: conseiller_numerique["Nom de la structure"],
      address: conseiller_numerique["Adresse de la structure"],
    },
  }.with_indifferent_access)

  # Re-invite the agent if the invitation has expired
  if agent.invitation_accepted_at.nil? && agent.invitation_sent_at < 1.month.ago
    agent.invite!(nil, validate: false)
  end

  puts "Import ou mise à jour réussie pour #{conseiller_numerique['Email @conseiller-numerique.fr']}"
end
