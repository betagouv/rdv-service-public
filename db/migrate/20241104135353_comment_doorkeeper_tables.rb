class CommentDoorkeeperTables < ActiveRecord::Migration[7.1]
  def change
    change_column_comment(:oauth_applications, :uid, from: nil, to: <<~COMMENT.strip
      Un identifiant unique de l'appication OAuth. Contrairement à la colonne `secret`, cette information est publique.
    COMMENT
    )

    change_column_comment(:oauth_applications, :secret, from: nil, to: <<~COMMENT
      Le secret de cette application, stocké de manière chiffrée comme les mots de passe.
    COMMENT
    )

    change_column_comment(:oauth_applications, :redirect_uri, from: nil, to: <<~COMMENT
      La liste des url de callback de cette application, séparés par des retours à la ligne. Attention à ne pas oublier de mettre ou d'enlever les slash de fin d'adresse en fonction du comportement de l'application cliente.
    COMMENT
    )

    change_column_comment(:oauth_applications, :scopes, from: nil, to: <<~COMMENT
      Pour le moment, on utilise uniquement le scope par défaut `write` pour toutes les applications, donc cette colonne sera toujours vide. Quand on commencera à affiner les permissions, on pourra commencer à utiliser cette colonne.
    COMMENT
    )

    change_column_comment(:oauth_applications, :confidential, from: nil, to: <<~COMMENT
      Cette colonne n'est pas utilisée, et sa valeur doit toujours être à true. Elle est prévue par la gem Doorkeeper pour être à false pour les applications dont le secret est public (SPA et applis mobiles). Ce n'est pas encore un cas d'usage qui nous concerne.
    COMMENT
    )

    change_column_comment(:oauth_access_tokens, :resource_owner_id, from: nil, to: <<~COMMENT
      L'id de l'agent qui a autorisé l'application.
    COMMENT
    )

    change_column_comment(:oauth_access_tokens, :token, from: nil, to: <<~COMMENT
      Le token qui perment d'authentifier des appels à notre api. Il est chiffré de manière similaire aux mots de passe.
    COMMENT
    )

    change_column_comment(:oauth_access_tokens, :scopes, from: nil, to: <<~COMMENT
      La liste des scopes d'autorisation liés au token. Pour le moment ça peut seulement être le scope unique `write`.
    COMMENT
    )

    change_column_comment(:oauth_access_tokens, :expires_in, from: nil, to: <<~COMMENT
      Le nombre de seconds avant l'expiration du token, par rapport à sa date de création.
    COMMENT
    )

    change_column_comment(:oauth_access_grants, :expires_in, from: nil, to: <<~COMMENT
      Le nombre de seconds avant l'expiration du grant, par rapport à sa date de création.
    COMMENT
    )
  end
end
