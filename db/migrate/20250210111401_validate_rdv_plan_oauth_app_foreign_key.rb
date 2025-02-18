class ValidateRdvPlanOauthAppForeignKey < ActiveRecord::Migration[7.1]
  def change
    validate_foreign_key :rdv_plans, :oauth_applications
  end
end
