require 'yahoo-finance'
namespace :db do
	desc "Fill database with sample data"
	task nk225: :environment do

		make_nk225
		# make_microposts
		# make_relationships
	end

	task :call_fetch_controller => :environment do
		# puts "aaaaaaaaaaaaaa"
		_controller = FetchController.new
		_controller.index


	end
end



def make_nk225
  # さかのぼりたい日数
  num_of_days=1000
  ticker="^N225"
  yahoo_client = YahooFinance::Client.new
  # data = yahoo_client.quotes(["BVSP", "NATU3.SA", "USDJPY=X"], [:ask, :bid, :last_trade_date])
  # data = yahoo_client.historical_quotes("^DJI", { raw: false, period: :monthly })
  arrData =
  yahoo_client.historical_quotes(ticker,
   { start_date: Time::now-(24*60*60*num_of_days),
     end_date: Time::now }) # 10 days worth of data
  p "count = #{arrData.count}"

  arrData.each do |data|
    # p "trade-date=#{data.trade_date}"
    trade_date_y=data.trade_date[0, 4]
    trade_date_m=data.trade_date[5,2]
    trade_date_d=data.trade_date[8,2]
    trade_date_ymd="#{trade_date_y}#{trade_date_m}#{trade_date_d}"
    trade_date_ymd=trade_date_ymd.to_i
    # p "ymd=" + trade_date_ymd.to_s

    open=data.open.to_f
    # p "open=" + open.to_s

    high=data.high.to_f
    # p "high=" + high.to_s

    low=data.low.to_f
    # p "low="+low.to_s

    close=data.adjusted_close.to_f
    # p "close=" + close.to_s

    volume=data.volume.to_f
    # p "volume=" + volume.to_s


    # すでにそのticker&YMDでPriceseriesモデルが存在していなければ
    arrPriceseries=Priceseries.where(ticker: ticker, ymd: trade_date_ymd).take
    if arrPriceseries != nil
      p arrPriceseries.ticker
      p "すでに存在しています"
      next

    end

    Priceseries.create!(
      ticker: ticker,
      name: "nikkei225",
      open: open,
      high: high,
      low: low,
      close: close,
      volume: volume,
      ymd: trade_date_ymd
    )

    p "追加" + Priceseries.last.ticker.to_s + ":" + Priceseries.last.ymd.to_s
  end

  p "最新データ"
  Priceseries.all.each do |data|
    # p data
    p data.ticker.to_s + ":" + data.ymd.to_s
  end
end
