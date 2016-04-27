class FeedsController < ApplicationController
  def index
    # kaminariでpaging
    @feeds = Feed.order("feed_id desc").paginate(page: params[:page])

    # p "page = #{@page}"
  end
  def show
    @feed = Feed.find(params[:id])

  end
end
