class AddVerticaleToOrganisations < ActiveRecord::Migration[7.0]
  def up
    create_enum :verticale, %i[rdv_insertion rdv_solidarites rdv_aide_numerique]

    add_column :organisations, :verticale, :verticale, default: :rdv_solidarites, null: false

    execute(<<-SQL.squish
      UPDATE organisations
      SET verticale = 'rdv_aide_numerique'
      WHERE new_domain_beta = TRUE
    SQL
           )

    remove_column :organisations, :new_domain_beta

    # Migrating rdv_insertion organisations will be done on demo and prod manually :
    # Organisation.where(id: [rdv_insertion_orgs_ids]).each { |org| org.verticale = :rdv_insertion; org.save }
  end

  def down
    add_column :organisations, :new_domain_beta, :boolean, default: false, null: false,
                                                           comment: "en mettant ce boolean a true, on active l'utilisation du nouveau domaine pour les conseillers numeriques de cette organisation"

    execute(<<-SQL.squish
      UPDATE organisations
      SET new_domain_beta = (verticale = 'rdv_aide_numerique')
    SQL
           )

    remove_column :organisations, :verticale
    drop_enum :verticale
  end
end
