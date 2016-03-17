class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :ymd
      t.string :name

      t.timestamps null: false
    end
  end
end
