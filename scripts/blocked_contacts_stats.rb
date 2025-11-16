# usage : bundle exec ruby scripts/blocked_contacts_stats.rb --path ~/Downloads/blocked-2025-04-28.csv
# download CSV from https://app-smtp.brevo.com/block

require "csv"
require "optparse"
require "debug"

options = Struct.new(:path).new
OptionParser.new do |opts|
  opts.on("-p", "--path PATH") { |o| options.path = o }
end.parse!

IGNORED_DOMAINS = %w[
  aliceadsl.fr
  aol.com
  bbox.fr
  cedis.fr
  deleted.rdv-solidarites.fr
  domaine.fr
  ecloud.com
  email.com
  free.fr
  gail.com
  gamail.com
  gamil.com
  gemail.com
  gmail.co
  gmail.com
  gmail.coml
  gmail.comm
  gmail.fr
  gmail.om
  gmal.com
  gmx.fr
  hotmail.com
  hotmail.fr
  icloud.com
  laposte.fr
  laposte.net
  live.com
  live.fr
  mail.com
  mail.ru
  msn.com
  neuf.fr
  numericable.fr
  orange.fr
  outlook.com
  outlook.fr
  sfr.fr
  test.fr
  wahoo.com
  wanadoo.fr
  yahoo.com
  yahoo.fr
  yahou.com
].freeze

rows = CSV.read(options.path, col_sep: ";", headers: true)
# debugger
rows
  .select { _1["Reason"].include?("hard bounce") }
  .map { _1["Contact"].split("@").last }
  .reject { IGNORED_DOMAINS.include?(_1) }
  .tally
  .select { |_k, v| v > 10 }
  .sort_by(&:last)
  .reverse
  .each { |domain, count| puts "#{count}\t#{domain}" }
