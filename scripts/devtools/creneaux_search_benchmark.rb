require "benchmark/ips"

motif_cn = Motif.find(1327) # Carte d'identité pour la mairie de Sèvres

motif_france_renov = Motif.find(767) # Le motif qui a le plus de plages d'ouverture de la db

motif_mehdi = Motif.find(14924) # Le motif de rdv d'accompagnement de Mehdi

Benchmark.ips do |x|
  # Configure the number of seconds used during
  # the warmup phase (default 2) and calculation phase (default 5)
  x.config(warmup: 2, time: 5)

  x.report("ants_creneaux_search") do
    # On trouve environ 1200 créneaux
    CreneauxSearch::Calculator.available_slots(motif: motif_cn, lieu: nil, agents: nil, date_range: (Time.zone.now..3.months.from_now))
  end

  x.report("france_renov_creneau_search") do
    CreneauxSearch::Calculator.available_slots(motif: motif_france_renov, lieu: nil, agents: nil, date_range: (Time.zone.now..1.week.from_now))
  end

  x.report("small_volume_creneau_search") do
    CreneauxSearch::Calculator.available_slots(motif: motif_mehdi, lieu: nil, agents: nil, date_range: (Time.zone.now..1.week.from_now))
  end
end
