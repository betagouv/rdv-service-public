class AddUsersDenormalizedOrganisationIds < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :denormalized_organisation_ids, :bigint, array: true, null: false, default: []

    safety_assured do
      execute <<~SQL.squish
        UPDATE users
        SET denormalized_organisation_ids = sub.organisation_ids
        FROM (
          SELECT user_id, ARRAY_AGG(DISTINCT organisation_id) AS organisation_ids
          FROM user_profiles
          GROUP BY user_id
        ) AS sub
        WHERE users.id = sub.user_id;
      SQL

      execute <<~SQL.squish
        CREATE INDEX index_users_on_org_ids_and_fts
        ON users
        USING GIN (
          denormalized_organisation_ids,
          text_search_terms_with_notification_email
        )
        WHERE deleted_at IS NULL;
      SQL
    end
  end

  def down
    remove_column :users, :denormalized_organisation_ids
  end
end
