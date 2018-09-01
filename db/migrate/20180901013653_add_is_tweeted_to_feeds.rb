class AddIsTweetedToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :is_tweeted, :integer
  end
end
