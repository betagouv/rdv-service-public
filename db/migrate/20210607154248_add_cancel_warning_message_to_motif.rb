# frozen_string_literal: true

class AddCancelWarningMessageToMotif < ActiveRecord::Migration[6.0]
  def change
    add_column :motifs, :cancel_warning_message, :text
  end
end
