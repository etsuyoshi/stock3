class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include SessionsHelper

  before_action :get_feed, :get_event
  # before_action :get_event

  #全コントローラー及びビュー内で使用可能なメソッドの定義
  helper_method :getTimeFromYMDHMS, :getYMDHMSFromTime, :getDocFromHtml, :isValidate

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
   startDay = today - 3600*24*5
   startYmd = startDay.strftime('%Y%m%d').to_i
   endDay = today + 3600*24*5
   endYmd = endDay.strftime('%Y%m%d').to_i
   @events = Event.where(ymd: (startYmd)..(endYmd)).order("ymd").limit(200)
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
