require "benchmark"
ActiveRecord::Base.logger = nil

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

# StackProf.run(mode: :cpu, out: 'tmp/stackprof-cpu-myapp.dump') do
# res = Benchmark.measure do
#   lieux.each do |lieu|
#     FindAvailabilityService.perform_with(
#       Motif.find(800).name,
#       lieu,
#       Date.today,
#       for_agents: true,
#       motif_location_type: Motif.find(800).location_type
#     )
#   end
# end
# puts(res)
# puts "----"
# puts(CreneauxBuilderForDateService.total_time)
# puts(FindAvailabilityService.total_time)
# puts(res.to_a.last)
# end
# 13s

puts "-----------"
puts "-----------"
puts "-----------"

# res = Benchmark.measure do
#   lieux.each do |lieu|
#     CreneauxBuilderService.perform_with(
#       motif_name,
#       lieu,
#       date_range,
#       for_agents: true,
#       motif_location_type: location_type
#     )
#   end
# end
# puts(res)

puts(
  Benchmark.measure do
    PlageOuverture
      .where(lieu: Lieu.find(151))
      .not_expired
      .joins(:motifs)
      .where(motifs: { name: "Je souhaite avoir un entretien avec mon référent", organisation_id: 101 })
      .includes(:motifs_plageouvertures, :motifs, agent: :absences)
      .to_a
  end
)


  # def index
  #   PlageOuverture
  #     .where(lieu: Lieu.find(151))
  #     .not_expired
  #     .joins(:motifs)
  #     .where(motifs: { name: "Je souhaite avoir un entretien avec mon référent", organisation_id: 101 })
  #     .to_a
  #     # .includes(:motifs_plageouvertures, :motifs, agent: :absences)
  # end

  def index
    # StackProf.run(mode: :cpu, out: 'tmp/stackprof-cpu-myapp.dump') do
    benchmark "benchmark around SearchCreneauxForAgentsService", silence: true do
      # SearchCreneauxForAgentsService.perform_with(
      #   OpenStruct.new(
      #     motif: Motif.find(800),
      #     agent_ids: nil,
      #     date_range: (Date.today..(Date.today + 6.days)),
      #     organisation: Organisation.find(101),
      #     lieu_ids: []
      #   )
      # )
      lieux = Organisation.find(101).lieux.for_motif(Motif.find(800)) # [153, 151, 344]
      # FindAvailabilityService.reset_time
      lieux.each do |lieu|
        FindAvailabilityService.perform_with(
          Motif.find(800).name,
          lieu,
          Date.today,
          for_agents: true,
          motif_location_type: Motif.find(800).location_type
        )
      end
      # puts("FindAvailabilityService.total_time : #{FindAvailabilityService.total_time}")
      # lieux.each do |lieu|
      #   CreneauxBuilderService.perform_with(
      #     Motif.find(800).name,
      #     lieu,
      #     (Date.today..(Date.today + 6.days)),
      #     for_agents: true,
      #     motif_location_type: Motif.find(800).location_type
      #   )
      # end
    # end
    # @search_results = []
    end
  end
