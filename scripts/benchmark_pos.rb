require "benchmark"
# ActiveRecord::Base.logger = nil

motif_name = "Je souhaite avoir un entretien avec mon référent"
location_type = "public_office"
date_range = (Date.today..(Date.today + 6.days))
lieux = Organisation.find(101).lieux.for_motif(Motif.find(800)) # [153, 151, 344]

# res = Benchmark.measure do
#   SearchCreneauxForAgentsService.perform_with(
#     OpenStruct.new(
#       motif: Motif.find(800),
#       agent_ids: nil,
#       date_range: date_range,
#       organisation: Organisation.find(101),
#       lieu_ids: []
#     )
#   )
# end
# puts res

res = Benchmark.measure do
  lieux.each do |lieu|
    FindAvailabilityService.perform_with(
      motif_name,
      lieu,
      date_range.begin,
      motif_location_type: location_type
    )
  end
end
puts(res)
# 13s

puts "-----------"
puts "-----------"
puts "-----------"

res = Benchmark.measure do
  lieux.each do |lieu|
    CreneauxBuilderService.perform_with(
      motif_name,
      lieu,
      date_range,
      for_agents: true,
      motif_location_type: location_type
    )
  end
end
puts(res)
