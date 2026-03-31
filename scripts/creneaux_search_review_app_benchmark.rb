require "benchmark/ips"

motif = Motif.find(7) # Etre rappelé par la PMI

Benchmark.ips do |x|
  # Configure the number of seconds used during
  # the warmup phase (default 2) and calculation phase (default 5)
  x.config(warmup: 2, time: 5)

  x.report("one week old version") do
    # On trouve environ 1200 créneaux
    CreneauxSearch::Calculator.available_slots(motif: motif, lieu: nil, agents: nil, date_range: (Time.zone.now..1.week.from_now), old_calculator: true)
  end

  x.report("three month old version") do
    CreneauxSearch::Calculator.available_slots(motif: motif, lieu: nil, agents: nil, date_range: (Time.zone.now..3.months.from_now), old_calculator: true)
  end

  x.report("one week new version") do
    # On trouve environ 1200 créneaux
    CreneauxSearch::Calculator.available_slots(motif: motif, lieu: nil, agents: nil, date_range: (Time.zone.now..1.week.from_now))
  end

  x.report("three month new version") do
    CreneauxSearch::Calculator.available_slots(motif: motif, lieu: nil, agents: nil, date_range: (Time.zone.now..3.months.from_now))
  end
end
