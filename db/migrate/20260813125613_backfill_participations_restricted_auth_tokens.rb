class BackfillParticipationsRestrictedAuthTokens < ActiveRecord::Migration[8.0]
  disable_ddl_transaction! # If the migration takes too much time and is killed, we still want to set as many tokens as possible

  def change
    up_only do
      Participation.joins(:rdv).where(restricted_auth_token: nil).where("rdvs.starts_at > ?", 3.months.ago).find_each do |participation|
        participation.send(:set_restricted_authentication_token)
        participation.save
      end
    end
  end
end
