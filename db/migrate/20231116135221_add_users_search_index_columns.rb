class AddUsersSearchIndexColumns < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :unaccented_last_name, :text
    add_column :users, :unaccented_first_name, :text
    add_column :users, :unaccented_birth_name, :text

    col_definition = <<~COLUMN
      setweight(to_tsvector('simple', coalesce("users"."unaccented_last_name" :: text, '')), 'A') ||
      setweight(to_tsvector('simple', coalesce("users"."unaccented_first_name" :: text, '')), 'B') ||
      setweight(to_tsvector('simple', coalesce("users"."unaccented_birth_name" :: text, '')), 'C') ||
      setweight(to_tsvector('simple', coalesce("users"."email" :: text, '')), 'D') ||
      setweight(to_tsvector('simple', coalesce("users"."phone_number_formatted" :: text, '')), 'D') ||
      setweight(to_tsvector('simple', coalesce("users"."id" :: text, '')), 'D')
    COLUMN

    add_column :users, :searchable, :virtual, type: :tsvector, as: col_definition, stored: true

    add_index :users, :searchable, using: :gin, name: "index_users_searchable"
  end
end
