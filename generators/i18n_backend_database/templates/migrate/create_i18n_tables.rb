class CreateI18nTables < ActiveRecord::Migration
  def self.up
    create_table :locales do |t|
      t.string   :code
      t.string   :name
    end
    add_index :locales, :code

    create_table :translations do |t|
      t.string   :key
      t.string   :raw_key
      t.string   :value
      t.integer  :pluralization_index, :default => 1
      t.integer  :locale_id
    end
    add_index :translations, [:locale_id, :key, :pluralization_index]

  end

  def self.down
    drop_table :locales
    drop_table :translations
    drop_table :asset_translations
  end
end
