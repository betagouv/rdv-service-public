Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :active_record # or :sequel, :redis
  strategy :default

  feature :visite_a_domicile,
          title: 'Visite à domicile',
          description: "Mise en place des visites à domicile"

  feature :corona,
          title: 'Corona',
          description: "Annonce suite au Coronavirus"

  feature :EHPAD,
          title: 'Visite en EHPAD',
          description: "Active le parcours dédié aux visites en EHPAD"
end
