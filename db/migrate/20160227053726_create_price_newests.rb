class CreatePriceNewests < ActiveRecord::Migration
  def change
    create_table :price_newests do |t|
      t.string :ticker
      t.float :pricetrade
      t.integer :datetrade
      t.float :ask
      t.float :bid

      t.timestamps null: false
    end
  end
end
