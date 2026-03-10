require "benchmark/ips"

motif = Motif.find(7) # Etre rappelé par la PMI

Benchmark.ips do |x|
  # Configure the number of seconds used during
  # the warmup phase (default 2) and calculation phase (default 5)
  x.config(warmup: 2, time: 5)

  x.report("one week ruby diff") do
    # On trouve environ 1200 créneaux
    CreneauxSearch::Calculator.available_slots(motif: motif, lieu: nil, agents: nil, date_range: (Time.zone.now..1.week.from_now), ruby_diff: true)
  end

  x.report("Three month ruby diff") do
    CreneauxSearch::Calculator.available_slots(motif: motif, lieu: nil, agents: nil, date_range: (Time.zone.now..3.months.from_now), ruby_diff: true)
  end

  x.report("one week pg diff") do
    # On trouve environ 1200 créneaux
    CreneauxSearch::Calculator.available_slots(motif: motif, lieu: nil, agents: nil, date_range: (Time.zone.now..1.week.from_now), ruby_diff: false)
  end

  x.report("Three month pg diff") do
    CreneauxSearch::Calculator.available_slots(motif: motif, lieu: nil, agents: nil, date_range: (Time.zone.now..3.months.from_now), ruby_diff: false)
  end
end
