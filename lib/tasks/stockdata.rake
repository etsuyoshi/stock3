require 'yahoo-finance'

#scrape255:
require 'nokogiri'
require 'open-uri'


namespace :db do
	desc "Fill database with sample data"

	#DBに存在するnikkei225ではないレコードを削除する
	task delete_nk225: :environment do
		ActiveRecord::Base.connection.execute("BEGIN TRANSACTION; END;")
		#nikkei225を取得
		nikkei225codes= get225code()

		#個別銘柄(-T)で225銘柄ではないものは全日程において削除


		tickers=Priceseries.pluck(:ticker).uniq

		#DBに保存されているtickerの中でnikkei225ではない銘柄を取得
		othersNikkei=(nikkei225codes-tickers) | (tickers-nikkei225codes)#比共通要素の取得

		#これだけでは為替とかも消去されてしまうので削除対象を個別銘柄にのみ絞る
		othersStockNikkei = othersNikkei.grep(/-T/)



		Priceseries.where(ticker: othersStockNikkei).delete_all#個別銘柄の複数指定の全消去

	end
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

		#まとめて実行する場合
		gets(Date.new(2016,11,10),#start
		 		 Date.new(2016,11,11))#end
				 next
		# next
		# p !HolidayJp.holiday?(Date.today)
		# p Date.today.to_s
		# p Time.now#heroku時間はNY-timeだが、以下コマンドで日本時間に設定可能(done)
		#heroku config:add TZ=Asia/Tokyo
		#next

		#日付選択はgets関数内部で実施済み
		#if Time.now.wday != 0 && Time.now.wday != 6
			#k-dbは15時40分に更新なので毎日16時に、当日が休日でなければという条件でcsvファイルを取得する
			#if !(HolidayJp.holiday?(Date.today))
		today_date = Date.today
		gets(today_date, today_date)
		# 	else
		# 		p '休日のため取得できません'
		# 	end
		# else
		# 	p "土日です"
		# end
	end

	task :call_fetch_controller => :environment do
		_controller = FetchController.new
		_controller.index
	end
end



#-----
def gets(fromDate, endDate)
  #fromDate = Date.new(2016, 11, 2)
  #endDate = Date.new(2016, 11, 2)
  date = fromDate




  while true do
		#与えられたdateが土日か休日でないならcsv取得（このパターンで拾えないのが大晦日・元旦）
		if !(date.wday == 0 || date.wday == 6 || (HolidayJp.holiday?(date)))
			p "date:#{date}で取得"
			get(date)
		end

		p "date = " + date.to_s
    if date == endDate
      break
    else
      date += 1
    end
		sleep(7)
  end
end

#指定された日付における全株価及び全指数のデータ（始値、引値など）を取得してPriceseriesに保存
def get(date)
	#url = "stocks"#http://k-db.com/stocks/2016-11-01?download=csv
	#url = "indices"#http://k-db.com/indices/2016-11-01?download=csv

	#日経225銘柄コードを取得する
	nikkei225codes=get225code()


	meta_datas = [["stocks","コード"], ["indices","指数"]]
	#meta_datas[0]
	#return
	meta_datas.each do |meta_data|
		content = meta_data[0]#stocks or indices
		key = meta_data[1]#コード or 指数

		results = getCSV(date, content)
		#p results
		if !results
			p "指定したデータは存在しません"
			return
		end

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

			#東証１部のみに限定する
			# if result["市場"] != "東証1部"
			# 	next#1部外であれば次の行を見に行く
			# end

			#個別銘柄(-T)では日経225銘柄に限定する:サブインデックスも追加する場合はここで別途指定する必要がある
			csv_code = result["コード"]
			if csv_code.last(2)=="-T"#最後の２文字が-Tならば個別銘柄なので225銘柄に含まれるかどうか判定し含まれるなら挿入対象としない
				if !nikkei225codes.include?(csv_code)
					next#日経225銘柄ではない場合次の行を見に行く
				end
			end

			ps = Priceseries.where(ticker: result[key]).where(ymd: ymd).first
			#該当銘柄(ticker)の該当日付(ymd)がDBに存在しなければ取得して保存する
			#p ps.to_s
			if ps == nil
				#日経平均の場合だけ元のデフォルト値の^N225に変換する
				if result[key] == "日経平均株価"
					name_mod = "nikkei225"
					ticker_mod = "^N225"
				else
					name_mod = result[key]
					ticker_mod = result[key]
				end

				ps =
				Priceseries.new(
				ticker: ticker_mod,
				 name: name_mod,
				 open: result["始値"],
				 high: result["高値"],
				 low: result["安値"],
				 close: result["終値"],
				 volume: result["出来高"],
				 ymd: ymd)

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
end



def getCSV(date, content) #date:2016-01-22
	#p "getCSV"
	p "getCSV:date = " + date.to_s
	p "getCSV:content = " + content.to_s
  agent = Mechanize.new
  #csv = agent.get_file("http://k-db.com/stocks/#{date}?download=csv")
	csv = agent.get_file("http://k-db.com/#{content}/#{date}?download=csv")
	#p "getCSV:#{!csv}"
	if !csv || csv==""
		return nil
	end

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


#更新はnikkei更新後のみで良い
#以下サイトから225銘柄のコードだけを一覧取得する
#https://indexes.nikkei.co.jp/nkave/index/component?idx=nk225
def get225code
	#html = Nokogiri::HTML(open('https://indexes.nikkei.co.jp/nkave/index/component?idx=nk225'))
	#logo = html.css('#hplogo').first # id="hplogo"
	#p html.css("div#container div#col-xs-12 col-sm-8 div#row component-list")
	#p html.css("div#container")
	# logo.name # タグ名
	# logo.attributes # 属性情報のハッシュ
	# logo.children # 子要素の配列
	# logo.content # タグの中身のテキストのみ
	# logo.inner_html # タグの中身のHTML
	#
	# p logo.inner_html


# <div class="container">
# 	<div class="col-xs-12 col-sm-8">
# 		<div class="row component-list">
# 			<div class="col-xs-3 col-sm-1_5">4151</div>
# 			<div class="col-xs-9 col-sm-2_5"><a href="http://www.nikkei.com/markets/company/index.aspx?scode=4151">協和キリン</a></div>
# 			<div class="hidden-xs col-sm-8">協和発酵キリン（株）</div>

	#コピペで取得したコード一覧
	return ['9532-T','9531-T','9503-T','9502-T','9501-T','9301-T','9202-T','9107-T','9104-T','9101-T','9064-T','9062-T','9022-T','9021-T','9020-T','9009-T','9008-T','9007-T','9005-T','9001-T','8830-T','8804-T','8802-T','8801-T','3289-T','7951-T','7912-T','7911-T','7012-T','7003-T','7013-T','7011-T','7004-T','6473-T','6472-T','6471-T','6367-T','6366-T','6361-T','6326-T','6305-T','6302-T','6301-T','6113-T','6103-T','5631-T','1963-T','1928-T','1925-T','1812-T','1808-T','1803-T','1802-T','1801-T','1721-T','8058-T','8053-T','8031-T','8015-T','8002-T','8001-T','2768-T','5901-T','5803-T','5802-T','5801-T','5715-T','5714-T','5713-T','5711-T','5707-T','5706-T','5703-T','3436-T','5541-T','5413-T','5411-T','5406-T','5401-T','5333-T','5332-T','5301-T','5233-T','5232-T','5214-T','5202-T','5201-T','5108-T','5101-T','5020-T','5002-T','6988-T','4911-T','4901-T','4452-T','4272-T','4208-T','4188-T','4183-T','4063-T','4061-T','4043-T','4042-T','4021-T','4005-T','4004-T','3407-T','3405-T','3865-T','3863-T','3861-T','3402-T','3401-T','3103-T','3101-T','1605-T','9766-T','9735-T','9681-T','9602-T','4755-T','4704-T','4689-T','4324-T','2432-T','9983-T','8267-T','8252-T','8233-T','8028-T','3382-T','3099-T','3086-T','2914-T','2871-T','2802-T','2801-T','2531-T','2503-T','2502-T','2501-T','2282-T','2269-T','2002-T','1333-T','1332-T','8795-T','8766-T','8750-T','8729-T','8725-T','8630-T','8628-T','8604-T','8601-T','8253-T','8411-T','8355-T','8354-T','8331-T','8316-T','8309-T','8308-T','8306-T','8304-T','8303-T','7186-T','9984-T','9613-T','9437-T','9433-T','9432-T','9412-T','7762-T','7733-T','7731-T','4902-T','4543-T','7272-T','7270-T','7269-T','7267-T','7261-T','7211-T','7205-T','7203-T','7202-T','7201-T','8035-T','7752-T','7751-T','7735-T','6976-T','6971-T','6954-T','6952-T','6902-T','6857-T','6841-T','6773-T','6770-T','6767-T','6762-T','6758-T','6752-T','6703-T','6702-T','6701-T','6674-T','6508-T','6506-T','6504-T','6503-T','6502-T','6501-T','6479-T','3105-T','4568-T','4523-T','4519-T','4507-T','4506-T','4503-T','4502-T','4151-T']


end
