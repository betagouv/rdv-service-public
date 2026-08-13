class BackfillParticipationsRestrictedAuthTokens < ActiveRecord::Migration[8.0]
  disable_ddl_transaction! # If the migration takes too much time and is killed, we still want to set as many tokens as possible

  def change
    # Cette migration est très lente à exécuter. Il faudra la préparer en faisant tourner ces 4 lignes dans la console de prod avant la mise en ligne
    Participation.where(restricted_auth_token: nil).find_each do |participation|
      participation.send(:set_restricted_authentication_token)
      participation.save
    end

    if Participation.where(restricted_auth_token: nil).any?
      raise "certaines participations n'ont pas pu être mise à jour"
    end
  end
end
