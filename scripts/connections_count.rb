# bundle exec rails runner scripts/connections_count.rb
# WARNING: ce fichier contient des eval de code lu depuis des fichiers de config

def display_ascii_table(headers, data)
  column_widths = headers.map.with_index do |header, index|
    [header.length, *data.map { |row| row[index].to_s.length }].max
  end
  separator = "|-#{column_widths.map { |width| '-' * width }.join('-|-')}-|"

  puts separator
  puts "| #{headers.map.with_index { |header, index| header.ljust(column_widths[index]) }.join(' | ')} |"
  puts separator

  data.each do |row|
    puts "| #{row.map.with_index { |cell, index| cell.to_s.ljust(column_widths[index]) }.join(' | ')} |"
  end

  puts separator
end

prod_env_values = `scalingo --region osc-secnum-fr1 --app production-rdv-solidarites env`
  .split("\n")
  .to_h { |line| line.split("=", 2).map(&:strip) }
  .slice("RAILS_MAX_THREADS", "GOOD_JOB_MAX_THREADS", "WEB_CONCURRENCY")
env_values = prod_env_values

connection_pools_max_sizes = File.read("config/database.yml")
  .lines
  .find { |line| line.include?("pool:") }
  .match(/<%= \$PROGRAM_NAME\.include\?\("good_job"\) \? (?<jobs>.*) : (?<web>.*) %>/)
  .named_captures
  .transform_values { _1.gsub("ENV", "env_values") }
  .transform_values { eval(_1) } # rubocop:disable Security/Eval
  .symbolize_keys

puma_max_threads_count = File.read("config/puma.rb")
  .lines
  .find { |line| line.include?("max_threads_count") }
  .sub("max_threads_count = ", "")
  .sub("ENV", "env_values")
  .then { eval(_1) } # rubocop:disable Security/Eval

good_job_max_threads_count = File.read("config/initializers/good_job.rb")
  .lines
  .find { |line| line.include?("max_threads = ") }
  .sub("config.good_job.max_threads = ", "")
  .to_i

max_threads_count_per_process = { jobs: good_job_max_threads_count, web: puma_max_threads_count }

scalingo_workers_count = `scalingo --region osc-secnum-fr1 --app production-rdv-solidarites scale`
  .gsub(" (*)", "")
  .lines
  .drop(3)
  .first(2)
  .map { _1.split("|").map(&:strip) } # rubocop:disable Style/MapToHash
  .to_h { [_1[1], _1[2].to_i] }
  .symbolize_keys

extra_connections_per_process = {
  web: 0,
  jobs: 3, # 2 pour les LISTEN/NOTIFY et 1 pour le cron
}
processes_per_worker = { jobs: 1 }
processes_per_worker[:web] = File.read("config/puma.rb")
  .lines
  .find { |line| line.include?("workers ENV") }
  .sub("workers ", "")
  .sub("ENV", "env_values")
  .then { eval(_1) } # rubocop:disable Security/Eval

total_max_connections = %i[web jobs].index_with do |worker_type|
  scalingo_workers_count[worker_type] *
    processes_per_worker[worker_type] *
    (connection_pools_max_sizes[worker_type] + extra_connections_per_process[worker_type])
end

total_max_threads = %i[web jobs].index_with do |worker_type|
  scalingo_workers_count[worker_type] *
    processes_per_worker[worker_type] *
    max_threads_count_per_process[worker_type]
end

headers = ["", "web", "jobs"]

def table_attr(name, attribute) = [name, attribute[:web], attribute[:jobs]]

puts "# Threads counts"

display_ascii_table(
  headers,
  [
    table_attr("scalingo_workers_count", scalingo_workers_count),
    table_attr("processes_per_worker", processes_per_worker),
    table_attr("max_threads_count_per_process", max_threads_count_per_process),
    ["-", "-", "-"],
    table_attr("total_max_threads", total_max_threads),
  ]
)

puts "\n\n Connections counts"

display_ascii_table(
  headers,
  [
    table_attr("scalingo_workers_count", scalingo_workers_count),
    table_attr("processes_per_worker", processes_per_worker),
    table_attr("connection_pools_max_sizes", connection_pools_max_sizes),
    table_attr("extra_connections_per_process", extra_connections_per_process),
    ["-", "-", "-"],
    table_attr("total_max_connections", total_max_connections),
  ]
)

puts "\ngrand total max connections : #{total_max_connections.values.sum}"
