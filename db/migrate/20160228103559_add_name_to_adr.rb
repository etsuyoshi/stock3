class AddNameToAdr < ActiveRecord::Migration
  def change
    add_column :adrs, :name, :string
  end
end
