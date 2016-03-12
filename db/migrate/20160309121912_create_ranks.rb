class CreateRanks < ActiveRecord::Migration
  def change
    create_table :ranks do |t|
      t.string :market
      t.integer :rank
      t.string :name
      t.string :sort
      t.float :changerate
      t.integer :changeprice
      t.float :nowprice

      t.timestamps null: false
    end
  end
end
