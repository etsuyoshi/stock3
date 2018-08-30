class AddDetailsToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :isTweeted, :integer
  end
end
