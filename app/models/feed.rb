class Feed < ActiveRecord::Base
  # acts_as_taggable_on :feedlabels # feed.feedlabel_list が追加される
  acts_as_taggable # feed.tag_listが追加される(default)=>tagged_withメソッドが使える
end
