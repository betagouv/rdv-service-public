# Tester les invitations depuis RDVSP

Le code qui génére le lien d'invitation dans le service de RDVI `Invitations::ComputeLink` dédié est présent dans ce fichier https://github.com/betagouv/rdv-insertion/blob/9c03e5a6c720a88826e84ca854fd5ccb6135569a/app/services/invitations/compute_link.rb#L2

Pour tester **depuis RDVSP** dans une console rails par exemple vous pouvez utiliser le code suivant.
`user` doit avoir un `rdv_invitation_token` assigné via la méthode `assign_rdv_invitation_token` et être sauvegardé.
Il doit faire parti de l'organisation.
`organisation` doit avoir un `motif` avec une catégorie de motif, la valeur de `bookable_by` doit être `:agents_and_prescripteurs_and_invited_users` et des plages d'ouvertures doivent être créées pour le motif.

```ruby
city_code = GeoCoding.new.get_geolocation_results(user.address, organisation.territory.departement_number)[:city_code]
street_ban_id = GeoCoding.new.get_geolocation_results(user.address, organisation.territory.departement_number)[:street_ban_id]
longitude, latitude = GeoCoding.new.find_geo_coordinates(user.address)
invitation_token = user.rdv_invitation_token
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
invitation_link = "#{ENV['HOST']}/prendre_rdv?#{attributes.to_query}"
```
