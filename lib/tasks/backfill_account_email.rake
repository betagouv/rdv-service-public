namespace :users do
  desc "Backfill account_email column with data from email column"
  task backfill_account_email: :environment do
    User.in_batches do |relation|
      # rubocop:disable Rails/SkipsModelValidations
      relation.where.not(email: nil).update_all("account_email = email")
      # rubocop:enable Rails/SkipsModelValidations
    end
    puts " Done!"
  end
end
