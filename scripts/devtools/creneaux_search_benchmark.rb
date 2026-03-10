require "benchmark/ips"

motif = Motif.find(1327) # Carte d'identité pour la mairie de Sèvres

Benchmark.ips do |x|
  # Configure the number of seconds used during
  # the warmup phase (default 2) and calculation phase (default 5)
  x.config(warmup: 2, time: 5)

  # Typical mode, runs the block as many times as it can
  x.report("creneaux_search") do
    # On trouve environ 1200 créneaux
    CreneauxSearch::Calculator.available_slots(motif: motif, lieu: nil, agents: nil, date_range: (Time.zone.now..3.months.from_now))
  end
end
