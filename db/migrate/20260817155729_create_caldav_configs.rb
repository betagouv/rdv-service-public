class CreateCaldavConfigs < ActiveRecord::Migration[8.0]
  CALDAV_ATTRIBUTES = %w[
    caldav_agenda_url caldav_username caldav_password
    caldav_sync_token caldav_disconnect_started_at caldav_include_sensitive_data
  ].freeze

  def up
    create_table :caldav_configs do |t|
      t.references :agent, null: false, foreign_key: true, index: { unique: true }
      t.string :caldav_agenda_url, null: false
      t.string :caldav_username, null: false
      t.string :caldav_password, null: false
      t.string :caldav_sync_token
      t.datetime :caldav_disconnect_started_at
      t.boolean :caldav_include_sensitive_data, default: false, null: false

      t.timestamps
    end

    # Agent n'a pas `encrypts` sur caldav_password : sa valeur brute est déjà le texte chiffré.
    # CaldavConfig, elle, a `encrypts` sur cette colonne : une simple affectation la rechiffrerait.
    # `without_encryption` permet d'écrire ce texte chiffré tel quel, sans le rechiffrer.
    ActiveRecord::Encryption.without_encryption do
      Agent.select(:id, *CALDAV_ATTRIBUTES).where.not(caldav_username: nil).each do |agent|
        CaldavConfig.create!(agent.attributes.slice(*CALDAV_ATTRIBUTES).symbolize_keys.merge(agent_id: agent.id))
      end
    end
  end

  def down
    # Agent.ignored_columns includes the caldav_* columns, so instance writer methods
    # (update!, []=, update_columns...) can't target them: update_all is the only way
    # to write these columns back through the Agent model.
    CaldavConfig.find_each do |caldav_config|
      Agent.where(id: caldav_config.agent_id).update_all(
        caldav_config.attributes.slice(*CALDAV_ATTRIBUTES).symbolize_keys.merge(
          caldav_password: caldav_config.ciphertext_for(:caldav_password)
        )
      )
    end

    drop_table :caldav_configs
  end
end
