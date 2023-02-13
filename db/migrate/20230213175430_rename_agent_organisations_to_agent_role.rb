# frozen_string_literal: true

class RenameAgentOrganisationsToAgentRole < ActiveRecord::Migration[7.0]
  def change
    rename_table :agents_organisations, :agent_roles
  end
end
