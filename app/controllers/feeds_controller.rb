class FeedsController < ApplicationController
  def index
    # kaminariでpaging
    @feeds = Feed.paginate(page: params[:page])
    

  end
  def show
    @feed = Feed.find(params[:id])

  end
end
