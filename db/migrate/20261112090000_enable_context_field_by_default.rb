class EnableContextFieldByDefault < ActiveRecord::Migration[8.0]
  def up
    change_column_default :territories, :enable_context_field, true

    # On exclut les espaces qui avaient activé puis désactivé explicitement
    opted_out_territory_ids = PaperTrail::Version
      .where(item_type: "Territory", event: "update")
      .where("object_changes @> ?::jsonb", { enable_context_field: [true, false] }.to_json) # @> = inclut
      .select(:item_id)
      .distinct

    already_enabled = Territory.where(enable_context_field: true)
    to_enable = Territory.where(enable_context_field: false).where.not(id: opted_out_territory_ids)
    to_leave_disabled = Territory.where(enable_context_field: false).where(id: opted_out_territory_ids)
    Rails.logger.info "- #{already_enabled.count} espaces ont déjà le champ contexte activé"
    Rails.logger.info "- #{to_enable.count} espaces vont voir le champ contexte être activé"
    Rails.logger.info "- #{to_leave_disabled.count} espaces vont rester sans champ contexte, car ils l'ont explicitement désactivé"

    PaperTrail.request(whodunnit: "migration EnableContextFieldByDefault") do
      to_enable.find_each { it.update!(enable_context_field: true) }
    end
  end

  def down
    change_column_default :territories, :enable_context_field, false
  end
end
