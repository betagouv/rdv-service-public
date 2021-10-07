# frozen_string_literal: true

class RdvAddRangeIndex < ActiveRecord::Migration[6.0]
  def change
    add_index :rdvs, "tsrange(starts_at, ends_at, '[)')", using: :gist
  end
end
