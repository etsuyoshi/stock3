# デザイン
# http://w-finder.com/cool
# http://photoshopvip.net/archives/17887

# リアルタイム機能
# http://blog.mlkcca.com/backend/milkcocoa-for-ror/

require 'yahoo-finance'

# nikkeiから値上がり率ランキング取得
require 'open-uri'# URLアクセス
require 'kconv'    # 文字コード変換
require 'nokogiri' # スクレイピング
require 'time'
require 'date'


class StaticPagesController < ApplicationController
  # 以下各ページに限定したニュースフィードだけでいいかも。
  # feedsモデルにカテゴリを追加→とりあえず最初はすべてのニュースで良い
  def nikkei
    @feed_news = Feed.order("feed_id desc").limit(40)

    @up_ranks = get_rank_hash("priceup")
    @down_ranks = get_rank_hash("pricedown")

  end
  def dow
    @feed_news = Feed.order("feed_id desc").limit(40)
  end
  def shanghai
    @feed_news = Feed.order("feed_id desc").limit(40)
  end
  def europe
    @feed_news = Feed.order("feed_id desc").limit(40)
  end
  def commodity
    @feed_news = Feed.order("feed_id desc").limit(40)
  end
  def bitcoin
    # bitcoinに限定したニュースだけでいいかも
    @feed_news = Feed.order("feed_id desc").limit(40)
  end
  def adr
    @feed_news = Feed.order("feed_id desc").limit(40)
  end
  def fx
    @feed_news = Feed.order("feed_id desc").limit(40)
  end
  def portfolio
    @feed_news = Feed.order("feed_id desc").limit(40)
  end
  def kessan
    @feed_news = Feed.order("feed_id desc").limit(40)
  end
  def home
    # bar-chart
    @end_at = Date.today
    @start_at = @end_at - 6
    @categories = @start_at.upto(@end_at).to_a
    @data = [5, 6, 3, 1, 2, 4, 7]

    # @h = LazyHighCharts::HighChart.new("graph") do |f|
    #   f.chart(:type => "column")
    #   f.title(:text => "Sample graph")
    #   f.xAxis(:categories => @categories)
    #   f.series(:name => "sample",
    #            :data => @data)
    # end

    # methodology1
    # jpstock
    # JpStock.price(:code=>"4689")
    # 個別銘柄->日経平均998407はだめだった
    # pre=JpStock.historical_prices(:code=>"1301", :start_date=>'2015/09/01', :end_date=>'2015/12/31')
    # 時系列取得方法
    # pre.each{ |data|
    #   p data
    #   date = data.date
    #   open = data.open
    #   high = data.high
    #   low = data.low
    #   close = data.close
    #
    #   # p "#{date}, #{close}"
    # }

    # methodology2
    # sorry_yahoo_financeは日経平均998407個別情報いける->日付指定はできない？
    # p YahooFinance.find("998407.O", lang: :en, format: :json)
    # p JSON.parse(YahooFinance.find("998407.O", date: Date.new(2015, 11, 28) .. Date.new(2015, 11, 29), format: :json, lang: :en))
    # p JSON.parse(YahooFinance.find(998407, date: Date.new(2015, 11, 28) .. Date.new(2015, 12, 3), format: :json, lang: :en))

    # to do list
    # stockhistoryモデルを作成して、date column, ohlcv(可能ならROEなどの財務指標)カラムを保存
    # controllerが開かれる毎に直近日付から当日までのデータを取得（必要なければしない）
    # methodology3
    # 銘柄コードを調べる方法
    # http://stackoverflow.com/questions/32899143/yahoo-finance-api-stock-ticker-lookup-only-allowing-exact-match?rq=1
    # http://d.yimg.com/aq/autoc?query=nikkei&region=US&lang=en-US&callback=YAHOO.util.ScriptNodeDataSource.callbacks

    # yahoo_client = YahooFinance::Client.new
    # # data = yahoo_client.quotes(["BVSP", "NATU3.SA", "USDJPY=X"], [:ask, :bid, :last_trade_date])
    # # data = yahoo_client.historical_quotes("^DJI", { raw: false, period: :monthly })
    # data = yahoo_client.historical_quotes("^N225", { start_date: Time::now-(24*60*60*100), end_date: Time::now }) # 10 days worth of data
    # p "data=#{data}"

    get_price_series

    gon.user_name="historical data"

    # try and error
    gon.historical_data=Priceseries.all.order(:ymd)


    @feed_news = Feed.order("feed_id desc").limit(40)

  end

  def help
  end

  def get_price_series
    # 既に格納されている最新データを取得


    todayObj = Time::now #ex. 2016-02-21 12:22:21 +0900
    newestYMD = Priceseries.maximum("ymd") #ex.20160122
    newestYear = newestYMD.to_s[0,4].to_i
    newestMonth = newestYMD.to_s[4,2].to_i
    newestDay = newestYMD.to_s[6,2].to_i

    if newestYear == todayObj.year &&
      newestMonth == todayObj.month &&
      newestDay   == todayObj.day
      p "本日まで取得済み"
    else
      p newestYMD.to_s + "から本日まで株価取得"
      # DBに保存されている最新データの日付
      newestObj = Time.zone.local(newestYear, newestMonth, newestDay)
      p newestObj
      p Time::now

      insert_PriceSeries("^N225", newestObj)
    end
  end


  def insert_PriceSeries(ticker, fromYmdObj)

    yahoo_client = YahooFinance::Client.new
    # data = yahoo_client.quotes(["BVSP", "NATU3.SA", "USDJPY=X"], [:ask, :bid, :last_trade_date])
    # data = yahoo_client.historical_quotes("^DJI", { raw: false, period: :monthly })
    # datas = yahoo_client.historical_quotes("^N225", { start_date: Time::now-(24*60*60*4), end_date: Time::now }) # 10 days worth of data
    datas = yahoo_client.historical_quotes(ticker, { start_date: fromYmdObj, end_date: Time::now})
    # p datas

    name = nil
    if ticker == "^N225"
      name = "nikkei225"
    else
      name = "notSet"
    end
    # 取得したデータ
    # <OpenStruct
    #  trade_date="2016-02-19",
    #  open="16050.400391",
    #  high="16050.459961",
    #  low="15799.349609",
    #  close="15967.169922",
    #  volume="156800",
    #  adjusted_close="15967.169922",
    #  symbol="^N225">

    # Priceseriesに格納する
    # Priceseries(id: integer,
    #   ticker: string,
    #   name: string,
    #   open: float,
    #   high: float,
    #   low: float,
    #   close: float,
    #   volume: float,
    #   ymd: integer,
    #   created_at: datetime,
    #   updated_at: datetime)

    datas.each do |data|
      # from "2016-02-19"-format to "20160219"
      datasDate = data.trade_date
      y = datasDate[0,4].to_s
      m = datasDate[5,2].to_s
      d = datasDate[8,2].to_s

      insertDate = y + m + d
      p insertDate



      priceOneDay = Priceseries.new(
        :ticker => ticker, #string,
        :name => name,#string,
        :open => data.open,#float,
        :high => data.high,#float,
        :low => data.low,#float,
        :close => data.close,#float,
        :volume => data.volume,#float,
        :ymd => insertDate#integer
        )


      priceOneDay.save



    end
  end

  def get_rank_hash(priceUpOrDown)
    # 値上がり率ランキング
    # url = "http://www.nikkei.com/markets/ranking/stock/priceup.aspx"
    url = "http://www.nikkei.com/markets/ranking/stock/" + priceUpOrDown.to_s + ".aspx"
    html = open(url) do |f|
      f.read # htmlを読み込んで変数htmlに渡す
    end

    # htmlをパース(解析)してオブジェクトを生成(utf-8に変換）
    doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')
    rank_all = Hash.new
    doc.xpath('//table[@class="tblModel-1"]').xpath('tr').each do |content|
      # p content
      # if content.xpath('tr').xpath('td').inner_text.to_i == 1
      #   p content.xpath('tr').xpath('td').xpath('a').inner_text
      # else
      #   p content.xpath('tr').xpath('td').xpath('a').inner_text
      # end

      rank_info = Hash.new
      rank = content.xpath('td[1]').inner_text.to_i


      if rank.kind_of?(Integer)
        rank2 = content.xpath('td[2]/a').inner_text #<- \r\tなどが含まれているので排除@rank_name
        stock_code = rank2[rank2.length-4,4]

        if stock_code
          rank_info["rank"] = rank
          rank_info["stock_code"] = stock_code
          rank_info["name"] = content.xpath('td[3]/a').attribute("title").value
          rank_info["return"] = content.xpath('td[5]').inner_text
          rank_info["price"] = content.xpath('td[6]').inner_text
          vsYesterday = content.xpath('td[7]').inner_text
          rank_info["vsYesterday"] = vsYesterday.match(/.*\r/)[0].sub(/\r/,"")
          p rank_info

          rank_all[rank] = rank_info
        end

      end
    end

    return rank_all
  end
end
