Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :active_record # or :sequel, :redis
  strategy :default

  feature :EHPAD,
          title: 'Visite en EHPAD',
          description: 'Active le parcours dédié aux visites en EHPAD'
end
