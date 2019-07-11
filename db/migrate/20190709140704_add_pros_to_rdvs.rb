class AddProsToRdvs < ActiveRecord::Migration[5.2]
  def change
    create_table :pros_rdvs, id: false do |t|
      t.belongs_to :pro, index: true
      t.belongs_to :rdv, index: true
    end
  end
end
