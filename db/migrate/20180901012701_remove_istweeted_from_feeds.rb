class RemoveIstweetedFromFeeds < ActiveRecord::Migration
  def change
    remove_column :feeds, :isTweeted, :integer
  end
end
