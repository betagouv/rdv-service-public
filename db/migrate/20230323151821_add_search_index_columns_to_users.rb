# frozen_string_literal: true

class AddSearchIndexColumnsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :unaccented_last_name, :string
    add_column :users, :unaccented_first_name, :string
    add_column :users, :unaccented_birth_name, :string
    add_index :users, "to_tsvector('simple'::regconfig, COALESCE(users.unaccented_last_name, ''::text))", using: :gin, name: "index_users_unaccented_last_name"
    add_index :users, "to_tsvector('simple'::regconfig, COALESCE(users.unaccented_first_name, ''::text))", using: :gin, name: "index_users_unaccented_first_name"
    add_index :users, "to_tsvector('simple'::regconfig, COALESCE(users.unaccented_birth_name, ''::text))", using: :gin, name: "index_users_unaccented_birth_name"

    add_column :agents, :unaccented_last_name, :string
    add_column :agents, :unaccented_first_name, :string
    add_index :agents, "to_tsvector('simple'::regconfig, COALESCE(agents.unaccented_last_name, ''::text))", using: :gin, name: "index_agents_unaccented_last_name"
    add_index :agents, "to_tsvector('simple'::regconfig, COALESCE(agents.unaccented_first_name, ''::text))", using: :gin, name: "index_agents_unaccented_first_name"

    up_only do
      # User.all.find_in_batches(batch_size: 10_000) do |users|
      #   updated_columns = users.map do |user|
      #     {
      #       id: user.id,
      #       unaccented_last_name: remove_accents_and_special_characters(user.last_name),
      #       unaccented_first_name: remove_accents_and_special_characters(user.first_name),
      #       unaccented_birth_name: remove_accents_and_special_characters(user.birth_name),
      #     }
      #   end
      #
      #   User.upsert_all(updated_columns)
      # end
      #
      # Agent.all.find_in_batches(batch_size: 10_000) do |agents|
      #   updated_columns = agents.map do |agent|
      #     {
      #       id: agent.id,
      #       unaccented_last_name: remove_accents_and_special_characters(agent.last_name),
      #       unaccented_first_name: remove_accents_and_special_characters(agent.first_name),
      #     }
      #   end
      #
      #   Agent.upsert_all(updated_columns)
      # end
    end
  end

  private

  def remove_accents_and_special_characters(string)
    return unless string

    I18n.transliterate(string).gsub(/[^0-9A-Za-z]/, "")
  end
end
