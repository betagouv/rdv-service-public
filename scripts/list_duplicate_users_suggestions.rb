# rails runner scripts/list_duplicate_users_suggestions.rb

ActiveRecord::Base.logger = nil # disable SQL output

class Stats
  def initialize(print_suggestions: "all")
    @results_by_organisation = {}
    @print_suggestions = print_suggestions
  end

  def perform
    puts "will go through #{Organisation.count} organisations...\n"
    Organisation.order(:departement).each { treat_organisation(_1) }
    puts "\n--- TOTALS ---\n"
    @results_by_organisation = @results_by_organisation.sort_by { _2.suggestions.count }
    @results_by_organisation.reverse.each { print_organisatio_result_row(_1, _2) }

    return unless @print_suggestions.present?

    puts "\n--- Suggestions by orga ---\n"
    @results_by_organisation.each { print_suggestions(_1, _2.suggestions) }
  end

  protected

  def treat_organisation(organisation)
    suggestions = nil
    time_ms = Benchmark.ms do
      suggestions = FindDuplicateUsersSuggestionsService
        .perform_with(organisation, hydrate_users: true)
    end

    @results_by_organisation[organisation] = \
      OpenStruct.new(suggestions: suggestions, time_ms: time_ms)
  end

  def orga_name_with_dpt(organisation)
    "#{organisation.departement} #{organisation.name}"
  end

  def print_organisatio_result_row(organisation, result)
    total_users = organisation.users.active.count
    percentage = ((result.suggestions.count.to_f / total_users) * 100).round if total_users.positive?
    cols = [
      orga_name_with_dpt(organisation)[0..15].ljust(16, " "),
      "#{result.suggestions.count.to_s.ljust(5, ' ')} suggestions",
      "out of #{total_users.to_s.ljust(5, ' ')} users",
      percentage ? "#{percentage} %" : "",
      "~#{result.time_ms.round} ms"
    ]
    puts cols.join("\t|\t")
  end

  def print_suggestions(organisation, suggestions)
    puts "\n--- Organisation #{orga_name_with_dpt(organisation)}  ---"
    puts "found #{suggestions.count} duplicate users suggestions"
    suggestions.each do |suggestion|
      users = suggestion.users.map(&:full_name).join(" - ")
      puts "#{suggestion.score.round(2)}: #{users}"
    end
  end
end

Stats.new.perform

# StackProf.run(mode: :cpu, out: "tmp/stackprof-duplicate-users.dump") do
#   FindDuplicateUsersSuggestionsService
#     .perform_with(Organisation.find_by_name("MDS Lens 2"), hydrate_users: true)
# end
