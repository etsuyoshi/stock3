class AddTickerToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :ticker, :string
  end
end
