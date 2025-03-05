class CreateAnnotations < ActiveRecord::Migration[7.1]
  def change
    create_table :annotations do |t|
      t.references :user, foreign_key: true, index: false, null: false
      t.references :territory, foreign_key: true, index: true, null: false

      t.string :content, null: false

      t.timestamps
    end

    add_index :annotations, %i[user_id territory_id], unique: true
  end

  private

  # Cette migration de données a pris 11 minutes sur une copie locale de la prod, c'est
  # pourquoi on la lance séparément pour ne pas que la migration timeout lors du deploy Scalingo.
  def a_lancer_manuellement
    User.where.not(notes: nil).where.not(notes: "").includes(:territories).find_each do |user|
      next if user.notes.blank? # pas la peine de migrer "   "

      user.territories.distinct.each do |territory|
        annotation = user.annotations.find_or_initialize_by(territory:)
        annotation.content = user.notes
        annotation.created_at = user.updated_at
        annotation.updated_at = user.updated_at
        annotation.save!
      end
    end
  end
end
