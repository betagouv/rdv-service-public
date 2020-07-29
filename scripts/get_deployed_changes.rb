# gem install ruby-trello
# then in terminal:
# irb -rubygems
# irb> require 'trello'
# irb> Trello.open_public_key_url                         # copy your public key
# irb> Trello.open_authorization_url key: 'yourpublickey' # copy your member token

# ruby scripts/get_deployed_changes.rb

require 'dotenv/load'
require 'trello'

Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
  config.member_token = ENV['TRELLO_MEMBER_TOKEN']
end

board = Trello::Board.find('5cdac252d7d01b6f728c0308')
list_deployed = board.lists.last
list_deployed.cards.each do |card|
  puts "- [#{card.name}](#{card.short_url})"
end

if ARGV[0] == '--archive'
  puts 'archiving all deployed cards...'
  list_deployed.archive_all_cards
  puts 'done'
end
