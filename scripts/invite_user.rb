# Un script pour tester les invitations en local depuis la console
#
# Typiquement, après avoir chargé les seeds, vous pouvez faire
# load "scripts/invite_user.rb"
# InviteUser.run_and_get_invitation_link!(User.find_by(email: "jean.rsavalence@testinvitation.fr"), Organisation.find_by(name: "Plateforme mutualisée d'orientation"))
# puis charger l'url renvoyée en local
class InviteUser
  def self.run_and_get_invitation_link!(user, organisation)
    invitation_token = user.set_rdv_invitation_token!
    motif = organisation.motifs.where.not(motif_category_id: nil).last

    city_code = GeoCoding.new.get_geolocation_results(user.address, organisation.territory.departement_number)[:city_code]
    street_ban_id = GeoCoding.new.get_geolocation_results(user.address, organisation.territory.departement_number)[:street_ban_id]
    longitude, latitude = GeoCoding.new.find_geo_coordinates(user.address)
    organisation_id = organisation.id
    motif_category_short_name = motif.motif_category.short_name
    address = user.address
    departement = organisation.territory.departement_number

    attributes = {
      longitude: longitude,
      latitude: latitude,
      city_code: city_code,
      street_ban_id: street_ban_id,
      departement: departement,
      address: address,
      invitation_token: invitation_token,
      organisation_ids: [organisation_id],
      motif_category_short_name: motif_category_short_name,
      # Optionnel : lieu spécifique et referents
      # lieu_id: 1
      # referent_ids: [1, 2]
    }

    "#{ENV['HOST']}/prendre_rdv?#{attributes.to_query}"
  end
end
