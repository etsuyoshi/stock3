class CreateAdrs < ActiveRecord::Migration
  def change
    create_table :adrs do |t|
      t.string :ticker
      t.string :tcode

      t.timestamps null: false
    end
  end
end
