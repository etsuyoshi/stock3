#require 'yahoo-finance'
namespace :db do
	desc "Fill database with sample data"
	task nk225: :environment do

		#yahoo動かなくなったらhttp://k-db.com/stocks/2016-10-21

		#make_nk225
		# make_microposts
		# make_relationships


		#priceseriesのカラム名を出力する
		# columns=Module.const_get('priceseries'.classify).columns
		# columns.each do |column|
		# 	p column.name + "," + column.sql_type
		# 	#<Priceseries id: 1, ticker: "^N225", name: "nikkei225", open: 16336.719727, high: 16993.960938, low: 16332.450195, close: 16958.529297, volume: 181200.0, ymd: 20160122, created_at: "2016-01-24 15:10:29", updated_at: "2016-01-24 15:10:29">
		# end
		#next

		gets
	end

	task :call_fetch_controller => :environment do
		# puts "aaaaaaaaaaaaaa"
		_controller = FetchController.new
		_controller.index
	end
end


#-----
def gets
	# p "aaa"
	# return
  fromDate = Date.new(2016, 1, 22)
  endDate = Date.new(2016, 1, 22)
  date = fromDate

  while true do
    get(date)
		p "date = " + date.to_s
    if date == endDate
      break
    else
      date += 1
    end
  end

end

def get(date)
  results = getCSV(date)

	year=date.to_s[0, 4]
	month=date.to_s[5,2]
	day=date.to_s[8,2]
	ymd="#{year}#{month}#{day}"
	ymd=ymd.to_i

	p "ymd= " + ymd.to_s
	#p results
	#p "code"
	#p results[1]["コード"]
  results.each do |result|

    # company = Company.where(code: result["コード"]).first_or_create
		# #company = Company.where(code: result["1301-T"]).first_or_create
    # company.name = result["銘柄名"]
    # company.save
    # company.prices.create(price: result["終値"], date: date)



		ps = Priceseries.where(ticker: result["コード"]).first
		if ps == nil
			ps =
			Priceseries.new(
			ticker: result["コード"],
			 name: result["銘柄名"],
			 open: result["始値"],
			 high: result["高値"],
			 low: result["安値"],
			 close: result["終値"],
			 volume: result["出来高"],
			 ymd: ymd
			 )

			 ps.save
		end

		# "id,INTEGER"
		# "ticker,varchar"
		# "name,varchar"
		# "open,float"
		# "high,float"
		# "low,float"
		# "close,float"
		# "volume,float"
		# "ymd,integer"
		# "created_at,datetime"
		# "updated_at,datetime"


  end
end

def getCSV(date) #date:2016-01-22
	#p "getCSV"
	p "getCSV:date = " + date.to_s
  agent = Mechanize.new
  csv = agent.get_file("http://k-db.com/stocks/#{date}?download=csv")
  csv = NKF.nkf('-wxm0', csv) #utf8に変換
  csv = csv.split("\r\n")
  keys = csv[0].split(",")
	#p keys.to_s

  rows = []

  csv.each_with_index do |v1,i1|
    next if i1 < 1
    row = {}

    v1.split(",").each_with_index do |v2,i2|
      row[keys[i2]] = v2
    end
    rows << row
  end
  return rows

end

#-----


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
