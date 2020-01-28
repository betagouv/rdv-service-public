class EnableUnaccentExtension < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'unaccent'
  end
end
