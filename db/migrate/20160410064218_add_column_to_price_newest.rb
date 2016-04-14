class AddColumnToPriceNewest < ActiveRecord::Migration
  def change
    add_column :price_newests, :previoustrade, :float
  end
end
