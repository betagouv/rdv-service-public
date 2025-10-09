# Pour savoir quels indexes sont utilisés, j'ai lancé cette commande :
#
# SELECT relname , indexrelname , idx_scan , idx_tup_read , idx_tup_fetch
# FROM pg_stat_user_indexes
# WHERE schemaname = 'public' and relname = 'receipts';
#
# => [
#  {"relname" => "receipts", "indexrelname" => "receipts_pkey", "idx_scan" => 1681725, "idx_tup_read" => 1760766, "idx_tup_fetch" => 1681725},
#  {"relname" => "receipts", "indexrelname" => "index_receipts_on_channel", "idx_scan" => 1, "idx_tup_read" => 0, "idx_tup_fetch" => 0},
#  {"relname" => "receipts", "indexrelname" => "index_receipts_on_created_at", "idx_scan" => 1899, "idx_tup_read" => 9307453699, "idx_tup_fetch" => 8047106287},
#  {"relname" => "receipts", "indexrelname" => "index_receipts_on_event", "idx_scan" => 0, "idx_tup_read" => 0, "idx_tup_fetch" => 0},
#  {"relname" => "receipts", "indexrelname" => "index_receipts_on_organisation_id", "idx_scan" => 25260, "idx_tup_read" => 161382114, "idx_tup_fetch" => 20266037},
#  {"relname" => "receipts", "indexrelname" => "index_receipts_on_rdv_id", "idx_scan" => 18977044, "idx_tup_read" => 44858454, "idx_tup_fetch" => 44775097},
#  {"relname" => "receipts", "indexrelname" => "index_receipts_on_result", "idx_scan" => 0, "idx_tup_read" => 0, "idx_tup_fetch" => 0},
#  {"relname" => "receipts", "indexrelname" => "index_receipts_on_user_id", "idx_scan" => 306106, "idx_tup_read" => 55972, "idx_tup_fetch" => 43327}
# ]
#
# On y voit que les indexes sur channel, event et result son inutilisés.

class RemoveUnusedIndexesOnReceipts < ActiveRecord::Migration[7.2]
  def change
    remove_index :receipts, :channel
    remove_index :receipts, :event
    remove_index :receipts, :result
  end
end
