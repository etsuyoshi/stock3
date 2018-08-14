class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include SessionsHelper
  include ApplicationHelper#ApplicationHelperのメソッドも他のcontrollerからもcallできるようにする

  before_action :get_feed, :get_event
  # before_action :get_event

  #全コントローラー及びビュー内で使用可能なメソッドの定義
  helper_method :getTimeFromYMDHMS, :getYMDHMSFromTime, :getDocFromHtmlWithJS, :getDocFromHtml, :isValidate

  #該当日付(yyyymmdd)に該当する日付のIR情報(feed)を取得する
  def getIrArrays(target_yyyymmdd)
    p "target_yyyymmdd = #{target_yyyymmdd}"
    irs_at_day=[]
    if target_yyyymmdd.to_s.length != 8
      p "8ではないので終了"
      return [];
    end
    Feed.tagged_with('kessan').where('title like ?', '%決算%').each do |feed_each|
      # p feed_each.title + "(#{Time.at(feed_each.feed_id.to_i).in_time_zone('Tokyo')})"
      begin
        p "loop" + Time.at(feed_each.feed_id.to_i).strftime('%Y%m%d').to_s
        if Time.at(feed_each.feed_id.to_i).strftime('%Y%m%d') == target_yyyymmdd
          irs_at_day.push(feed_each)
        end
      rescue #エンコードや文字カウント絡みで何かしらのエラーが発生した時は無視して次を見る
        next
      end
    end
    return irs_at_day
  end

  def getMarketSchedules(target_yyyymmdd)
    schedules_at_day = [];
    if target_yyyymmdd.to_s.length != 8
      p "8ではないので終了"
      return [];
    end
    Feed.where(keyword: 'market_schedule').each do |feed_each|
      begin
        if Time.at(feed_each.feed_id.to_i).strftime('%Y%m%d') == target_yyyymmdd
          schedule_at_day.push(feed_each)
        end
      rescue
        next
      end
    end
    return schedules_at_day
  end

  # string型のurlからhtmlを取得する
  def getDocFromHtml(url_string)

    # if !(url_string.include?("kabutan"))
    if url_string.include?("finance.yahoo")
      # https://finance.yahoo.co.jpだけはasciiコードに変換しないとだめ
      url_encoded = URI.encode(url_string).gsub(/=/,"%3D").gsub(/\?/,"%3F")
    else
      # kabutanの場合には=や？はそのままにする
      url_encoded = url_string
    end
    if !isValidate(url_encoded)
      p "そのURLは無効です <- #{url_encoded}"
      return nil;
    end
    p url_encoded


    charset = nil
    html = open(url_encoded) do |f|
      charset = f.charset # 文字種別を取得
      f.read # htmlを読み込んで変数htmlに渡す
    end
    doc = Nokogiri::HTML.parse(html, nil, charset)
    return doc
  end

  #url_encodeするとうまく正しく遷移しない場合があるので、渡す際にencodeしているようにする！
  def getDocFromHtmlWithJS(url_encoded)
    # url_encoded = URI.encode(url_string)

    # javascriptが動いているのでphantomjs(Capybaraによるpoltergeist)を使ってjs実行後のhtmlを取得する
    #poltergistの設定
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, {:js_errors => false, :timeout => 1000 }) #追加のオプションはググってくださいw
    end
    Capybara.default_selector = :xpath
    session = Capybara::Session.new(:poltergeist)
    #自由にUser-Agent設定してください。
    session.driver.headers = { 'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X)" }
    #session.visit "https://fx.minkabu.jp/indicators"
    session.visit url_encoded
    sleep(1)
    output_html = session.html
    session.driver.quit
    return Nokogiri::HTML.parse(output_html)
  end

  def isValidate(url_string, limit = 10)
		begin
	    response = Net::HTTP.get_response(URI.parse(URI.encode(url_string)))
	  rescue
			# p "error"
	    return false
	  else
	    case response
	    when Net::HTTPSuccess
				# p "success"
	      return true
	    when Net::HTTPRedirection
				# p "redirect"
	      isValidate(response['location'], limit - 1)
	    else
	      return false
	    end
	  end

		return true
	end


  def getTimeFromYMDHMS(yyyymmddhhmmss)
    #14桁の文字列でなければゼロを返す
    unless yyyymmddhhmmss.is_a? String
      return 0
    end
    unless yyyymmddhhmmss.length == 14
      return 0
    end
    _YY = yyyymmddhhmmss[0..3]
    _MM = yyyymmddhhmmss[4..5]
    _DD = yyyymmddhhmmss[6..7]
    _hh = yyyymmddhhmmss[8..9]
    _mm = yyyymmddhhmmss[10..11]
    _ss = yyyymmddhhmmss[12..13]
    return Time.mktime(_YY, _MM, _DD, _hh, _mm, _ss, 0)#最後のゼロは秒数の小数点以下
  end
  #時間オブジェクトからyyyymmddhhmmssを返す
  def getYMDHMSFromTime(_time)
    unless _time.is_a? Time
      return "0"
    end
    return _time.strftime("%Y%m%d%H%M%S")
  end


  def get_feed
     @feed_news = Feed.order("feed_id desc").where(Feed.arel_table[:feed_id].lteq(Time.new().to_i)).limit(20)
  end

 def get_event
   #  ５日分のデータを取得する
   today = Time.now
   # startDay = today - 3600*24*5
   # startYmd = startDay.strftime('%Y%m%d').to_i
   # endDay = today + 3600*24*5
   # endYmd = endDay.strftime('%Y%m%d').to_i
   # @events = Event.where(ymd: (startYmd)..(endYmd)).order("ymd").limit(200)


   #決算情報と統計情報だけ取り出す
   start_unixtime = Time.now.to_i #today.to_time.to_i - 3600*24*5 #
   end_unixtime = today.to_time.to_i + 3600*24*5
   kessan_feeds = Feed.where(Feed.arel_table[:feed_id].gteq(start_unixtime)).where(Feed.arel_table[:feed_id].lteq(end_unixtime)).tagged_with('kessan').order(ticker: :desc).order(feed_id: :desc)
   index_feeds = Feed.where(Feed.arel_table[:feed_id].gteq(start_unixtime)).where(Feed.arel_table[:feed_id].lteq(end_unixtime)).where(keyword: 'market_schedule').order(ticker: :desc).order(feed_id: :desc)
   # @event_feeds = (kessan_feeds + index_feeds).uniq.sort_by{ |v|  [+(v.feed_id), v.ticker.to_s]}.reverse
   @event_feeds = nil
   if kessan_feeds.count>0 && index_feeds.count>0
     @event_feeds = kessan_feeds + index_feeds
   elsif kessan_feeds.count>0
     @event_feeds = kessan_feeds
   elsif index_feeds.count>0
     @event_feeds = index_feeds
   end
   @event_feeds = @event_feeds.uniq.sort_by{ |v|  [(v.feed_id), v.ticker.to_s]}.reverse

   #uniq.sort_by{ |v|  v['ticker'] }.reverse.sort_by{ |v|  v['feed_id'] }.reverse#降順





    # Feed.(where(Feed.arel_table[:feed_id].gteq(start_unixtime)).where(Feed.arel_table[:feed_id].lteq(end_unixtime)).tagged_with('kessan')).or(Feed.tagged_with('market_schedule'))

   #kessans = Feed.where(Feed.arel_table[:feed_id].gteq(from_unixtime)).where(Feed.arel_table[:feed_id].lteq(to_unixtime)).tagged_with('kessan')
 end


  private
  #  ユーザーのログインを確認する
  def logged_in_user

    unless logged_in?
      store_location
      flash[:danger] = "Please log in"
      redirect_to login_url
    end
  end
end
