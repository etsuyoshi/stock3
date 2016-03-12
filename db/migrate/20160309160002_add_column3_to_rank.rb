class AddColumn3ToRank < ActiveRecord::Migration
  def change

    # 削除
    remove_column :ranks, :vsYesterday, :float
    remove_column :ranks, :return, :float
    remove_column :ranks, :changerate, :float
    remove_column :ranks, :changeprice, :float

    # 追加
    add_column :ranks, :vsYesterday, :string
    add_column :ranks, :return,      :string



  end
end
