class AddKeywordsToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :keyword, :string
  end
end
