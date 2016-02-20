# デザイン
# http://w-finder.com/cool
# http://photoshopvip.net/archives/17887

# リアルタイム機能
# http://blog.mlkcca.com/backend/milkcocoa-for-ror/

require 'yahoo-finance'
class StaticPagesController < ApplicationController
  def nikkei
  end
  def dow
  end
  def shanghai
  end
  def europe
  end
  def commodity
  end
  def adr
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

    yahoo_client = YahooFinance::Client.new
    # data = yahoo_client.quotes(["BVSP", "NATU3.SA", "USDJPY=X"], [:ask, :bid, :last_trade_date])
    # data = yahoo_client.historical_quotes("^DJI", { raw: false, period: :monthly })
    data = yahoo_client.historical_quotes("^N225", { start_date: Time::now-(24*60*60*10), end_date: Time::now }) # 10 days worth of data
    p "data=#{data}"

    gon.user_name="historical data"

    # try and error
    gon.historical_data=Priceseries.all.order(:ymd)


    @feed_news = Feed.order("feed_id desc").limit(40)
    p @feed_news
  end

  def help
  end
end
