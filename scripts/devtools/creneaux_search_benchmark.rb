require "benchmark/ips"

Benchmark.ips do |x|
  # Configure the number of seconds used during
  # the warmup phase (default 2) and calculation phase (default 5)
  x.config(warmup: 2, time: 5)

  # Typical mode, runs the block as many times as it can
  x.report("creneaux_search") do
    CreneauxSearch::Calculator.available_slots(motif: Motif.last, lieu: nil, agents: nil, date_range: (Time.zone.now..3.months.from_now))
  end
end
