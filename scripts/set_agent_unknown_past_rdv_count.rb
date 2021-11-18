# frozen_string_literal: true

# See AddUnknowPastRdvCountToAgents
# Set the initial values for Agent.unknow_past_rdv_count

unknown_rdv_count_by_agent = Rdv.status("unknown_past").joins(:agents_rdvs).group("agents_rdvs.agent_id").count
Rails.logger.info "Setting Agent.unknow_past_rdv_count for #{unknown_rdv_count_by_agent.size} agents…"
unknown_rdv_count_by_agent.each_with_index do |values, index|
  agent_id, unknow_past_rdv_count = values
  # Update the row without instanciating and without validation
  Agent.where(id: agent_id).update_all(unknow_past_rdv_count: unknow_past_rdv_count) # rubocop:disable Rails/SkipsModelValidations
  Rails.logger.info "#{index + 1}/#{unknown_rdv_count_by_agent.size}"
end
Rails.logger.info "Done!"
