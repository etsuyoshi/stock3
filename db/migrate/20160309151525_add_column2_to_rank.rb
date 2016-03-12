class AddColumn2ToRank < ActiveRecord::Migration
  def change
    add_column :ranks, :vsYesterday, :float
    add_column :ranks, :return, :float
  end
end
