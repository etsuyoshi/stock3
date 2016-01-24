class SetUniqueTickerAndYmd < ActiveRecord::Migration
  def change
    add_index :Priceseries, [:ticker, :ymd], :unique => true
  end
end
