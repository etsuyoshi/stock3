class AddColumnToRank < ActiveRecord::Migration
  def change
    add_column :ranks, :stock_code, :string
  end
end
