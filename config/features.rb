Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :active_record # or :sequel, :redis
  strategy :default

  feature :file_attente,
          title: "File d'attente",
          description: "Permettre aux usagers de s'inscrire sur une liste d'attente"
end
