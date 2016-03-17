class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include SessionsHelper

  before_action :get_feed, :get_event
  # before_action :get_event


  def get_feed
     @feed_news = Feed.order("feed_id desc").limit(20)
   end

   def get_event
     today = Time.now
     startDay = today - 3600*24*5
     startYmd = startDay.strftime('%Y%m%d').to_i
     endDay = today + 3600*24*5
     endYmd = endDay.strftime('%Y%m%d').to_i
     @events = Event.where(ymd: (startYmd)..(endYmd)).order("ymd").limit(200)
   end
end
