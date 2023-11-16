class BackfillUsersSearchIndexColumns < ActiveRecord::Migration[7.0]
  def up
    User.where(unaccented_last_name: nil).find_each do |user|
      user.update_columns(
        unaccented_last_name: user.last_name.presence && I18n.transliterate(user.last_name).downcase,
        unaccented_first_name: user.first_name.presence && I18n.transliterate(user.first_name).downcase,
        unaccented_birth_name: user.birth_name.presence && I18n.transliterate(user.birth_name).downcase
      )
    end
  end

  def down; end
end
