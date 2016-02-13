class CreateFeeds < ActiveRecord::Migration
  def change
    create_table :feeds do |t|
      t.string :feed_id
      t.string :title
      t.text :description
      t.string :link

      t.timestamps null: false
    end
  end
end
