class CreateAnnotations < ActiveRecord::Migration[7.1]
  def change
    create_table :annotations do |t|
      t.references :user, foreign_key: true, index: true, null: false
      t.references :territory, foreign_key: true, index: true, null: false

      t.string :content, null: false

      t.timestamps
    end

    reversible do |direction|
      direction.up do
        User.where.not(notes: nil).where.not(notes: "").includes(:territories).find_each do |user|
          next if user.notes.blank? # pas la peine de migrer "   "

          user.territories.each do |territory|
            Annotation.create!(
              user: user,
              territory: territory,
              content: user.notes,
              created_at: user.updated_at,
              updated_at: user.updated_at
            )
          end
        end
      end
    end
  end
end
