class CreateDoorkeeperTables < ActiveRecord::Migration[7.1]
  def change
    create_table :oauth_applications do |t|
      t.string  :name,    null: false
      t.string  :uid,     null: false
      # TODO: voir si on a quand même du chiffrage avec des colonnes string
      t.text :secret, null: false # On utilise une colonne text plutôt que de type string comme le proposer doorkeeper par défaut pour pouvoir chiffrer cette colonne

      t.text    :redirect_uri, null: false
      t.string  :scopes,       null: false, default: ""
      t.boolean :confidential, null: false, default: true
      t.timestamps             null: false
    end

    add_index :oauth_applications, :uid, unique: true

    create_table :oauth_access_grants do |t|
      t.references :resource_owner, null: false
      t.references :application,     null: false
      t.string   :token,             null: false
      t.integer  :expires_in,        null: false
      t.text     :redirect_uri,      null: false
      t.string   :scopes,            null: false, default: ""
      t.datetime :created_at,        null: false
      t.datetime :revoked_at
    end

    add_index :oauth_access_grants, :token, unique: true
    add_foreign_key :oauth_access_grants, :oauth_applications, column: :application_id, validate: false

    create_table :oauth_access_tokens do |t|
      t.references :resource_owner, index: true

      t.references :application, null: false

      t.text :token, null: false # On utilise une colonne text plutôt que de type string comme le proposer doorkeeper par défaut pour pouvoir chiffrer cette colonne

      t.text :refresh_token # On utilise une colonne text plutôt que de type string comme le proposer doorkeeper par défaut pour pouvoir chiffrer cette colonne
      t.integer  :expires_in
      t.string   :scopes
      t.datetime :created_at, null: false
      t.datetime :revoked_at

      # The authorization server MAY issue a new refresh token, in which case
      # *the client MUST discard the old refresh token* and replace it with the
      # new refresh token. The authorization server MAY revoke the old
      # refresh token after issuing a new refresh token to the client.
      # @see https://datatracker.ietf.org/doc/html/rfc6749#section-6
      #
      # Doorkeeper implementation: if there is a `previous_refresh_token` column,
      # refresh tokens will be revoked after a related access token is used.
      # If there is no `previous_refresh_token` column, previous tokens are
      # revoked as soon as a new access token is created.
      #
      # Comment out this line if you want refresh tokens to be instantly
      # revoked after use.
      t.text :previous_refresh_token, null: false, default: ""
    end

    add_index :oauth_access_tokens, :token, unique: true
    add_index :oauth_access_tokens, :refresh_token, unique: true

    add_foreign_key :oauth_access_tokens, :oauth_applications, column: :application_id, validate: false

    add_foreign_key :oauth_access_grants, :agents, column: :resource_owner_id, validate: false
    add_foreign_key :oauth_access_tokens, :agents, column: :resource_owner_id, validate: false
  end
end
