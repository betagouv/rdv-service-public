# frozen_string_literal: true

class AddDefaultValueToRdvsUsersCount < ActiveRecord::Migration[6.1]
  def change
    change_column_default :rdvs, :users_count, from: nil, to: 0
  end
end
