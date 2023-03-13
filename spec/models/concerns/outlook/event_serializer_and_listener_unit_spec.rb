# frozen_string_literal: true

# Ce fichier teste que le bon nombre de jobs est envoyé pour différentes transactions
RSpec.describe Outlook::EventSerializerAndListener, database_cleaner_strategy: :truncation do
  let(:agent) { create(:agent, microsoft_graph_token: "token") }
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, email: "user@example.fr", first_name: "First", last_name: "Last", organisations: [organisation]) }
end
