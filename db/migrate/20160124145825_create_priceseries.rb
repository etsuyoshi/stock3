class CreatePriceseries < ActiveRecord::Migration
  def change
    create_table :priceseries do |t|
      t.string :ticker
      t.string :name
      t.float :open
      t.float :high
      t.float :low
      t.float :close
      t.float :volume
      t.integer :ymd

      t.timestamps null: false
    end
  end
end
