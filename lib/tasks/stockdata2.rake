# 世界の株価動向を一覧・一目で見れる
# 値上がり傾向、値下がりトップ５
# Rankモデルの更新場所はどこ？(FetchControllerで更新確認)→static_pages#nikkeiで取得して、static_pages/nikkei.html.erbで使用している
# herokuのschedulerで更新する
# 使い方をheroku run rails consoleで確認する
# ModesNames.column_names
# Priceseries.columns.map(&:type)
# Priceseries.columns.map(&:name)


require 'yahoo-finance'
require 'uri'
require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'

namespace :db do
	desc "Fill database with sample data"

	task :delete_unused => :environment do
		# 使っていないタグを削除する
		delete_unused_tags()
  end


	task gg: :environment do
		_controller = FetchController.new
		_controller.gg("インターネット")
	end

	task fetcher: :environment do
		# Priceseries更新
		updatePrice()
		updateRank()
		get_news()
		delete_unused_tags()
	end
	# データが回ってない時の緊急実行用
	task updatePrice: :environment do
		updatePrice()
	end
	task updateRank: :environment do
		updateRank()
	end
	task getNews: :environment do
		get_news()
	end

	def delete_unused_tags()
		# 使っていないタグを削除する
		ActsAsTaggableOn::Tag.joins(
			"LEFT JOIN taggings on taggings.tag_id = tags.id").where("taggings.id is null").delete_all
		ActsAsTaggableOn::Tagging.joins(
			"LEFT JOIN tags on tags.id = taggings.tag_id").where("tags.id is null").delete_all
	end


	def get_news
		# FetchController#get_news()を実行する
		_controller = FetchController.new
		_controller.index
	end


	def get_btc_api
		# https://qiita.com/awakia/items/bd8c1385115df27c15fa
		uri = URI.parse('https://apiv2.bitcoinaverage.com/indices/global/history/BTCUSD?period=alltime&format=json')
		json = Net::HTTP.get(uri)
		result = JSON.parse(json)

		if result.nil?
			p "btcヒストリカル：取得エラー"
			return
		end
		# 既存データ消去
		Priceseries.where(ticker: "btci").delete_all
		# 最新の100日分のみ取得
		result[0..29].each do |btc_daily|
			p btc_daily["time"]
			open_value = btc_daily["open"]
			high_value = btc_daily["high"]
			low_value = btc_daily["low"]
			close_value = btc_daily["average"]
			volume_value = btc_daily["volume"]
			ymd_value = Date.parse(btc_daily["time"]).to_time.in_time_zone('Tokyo').to_i
			# p "ymd: #{Time.at(ymd_value).strftime('%Y-%m-%d')}, open: #{open_value}, high: #{high_value}, low: #{low_value}, close: #{close_value}"

			ps = Priceseries.new(
				ticker: "btci",
				name: "bitcoin",#名前をスクレイピングして取得するのも良い
				open: open_value,
				high: high_value,
				low: low_value,
				close: close_value,
				volume: volume_value,
				ymd: ymd_value)
			ps.save
		end
		return
  end



	# rank dataの更新
	# task rank: :environment do
	def updateRank()
		_controller = RankController.new
		_controller.index
	end

	# 長く更新されていないデータを削除する
	# 1週間に一回くらいやればいい
	# task cleanup: :environment do
	def cleanPriceseries()
		# 5日以上更新されていないデータは削除する
		old_priceseries = Priceseries.where(Priceseries.arel_table[:updated_at].lteq(Date.today.in_time_zone('Tokyo')-5*24*3600))
		old_priceseries.delete_all
		old_priceseries.save
	end

	# task updatePrice: :environment do
	def updatePrice()
		# ビットコインヒストリカルデータの取得
		get_btc_api()

		# 日経平均を中心にkabutanで取得できる国内銘柄
		arrCode = getKabutanTicker()
    # 一気に250銘柄進めようとすると負荷をかけてしまうためまずい→updated_atを見ながら当日取得していない銘柄を5銘柄ずつくらい取得する
		if !arrCode.nil?
	    arrCode.each do |code|
				ticker_without_t = code.gsub(/-T/, '').to_s
	      getPriceKabutan(ticker_without_t)
	    end
		end

		#株価指数(YahooFinanceで取得可能なもの)
		arrCode = getYahooTicker()
		if !arrCode.nil?
			arrCode.each do |code|
				getPriceYahoo(code)
			end
		end
	end


  # k-dbサービス終了に伴い、別の方法を検討
  # 日経銘柄：kabutan
  # dji : https://finance.yahoo.com/quote/%5EDJI/history?p=%5EDJI
  # sp5 : https://finance.yahoo.com/quote/%5EGSPC/history?p=%5EGSPC
  # gld : https://finance.yahoo.com/quote/GC=F?p=GC=F
	def getPriceYahoo(ticker)
		# url_price = "https://finance.yahoo.com/quote/%5EDJI/history?p=%5EDJI"
		# ticker_for_url = ^FTSE?P=FTSE
		# if ticker == "^FTSE"
		# 	# ticker
		# 	url_price = "https://finance.yahoo.com/quote/%5EFTSE%3FP%3DFTSE/history/"
		# else
			url_price = "https://finance.yahoo.com/quote/#{ticker.to_s}/history"
			# url_price = "https://finance.yahoo.com/quote/#{ticker.to_s}/history?p=#{ticker.to_s}"
		# end
		doc = ApplicationController.new.getDocFromHtml(url_price)

		if doc.nil?
			return
		end

		if doc.css('tbody').nil? || doc.css('h1').nil?
			return
		end
		name = doc.css("h1").text


		price_datas = doc.css('tbody')[0].css('tr')
		# すでにあれば削除する
		if price_datas.count > 0
			if Priceseries.where(ticker: ticker.to_s).count > 0
				Priceseries.where(ticker: ticker.to_s).delete_all
			end
		end
		price_datas.each do |price_row|
			if Priceseries.where(ticker: ticker.to_s).count >= 30
				break
			end
			# 配当データの表示などでprice_now.css('td')[1].text==nilの時が存在する
			if price_row.css('td')[0].nil? ||
				price_row.css('td')[1].nil? ||
				price_row.css('td')[2].nil? ||
				price_row.css('td')[3].nil? ||
				price_row.css('td')[4].nil? ||
				price_row.css('td')[5].nil?
				next
			end
			# Date, Open, High, Low, Close, Volume
			row_date  = Date.parse(price_row.css('td')[0].text).to_time.in_time_zone('Tokyo').to_i#to_iでunix_time変換
			row_open  = price_row.css('td')[1].text.gsub(/,/,"").to_f
			row_high  = price_row.css('td')[2].text.gsub(/,/,"").to_f
			row_low   = price_row.css('td')[3].text.gsub(/,/,"").to_f
			row_close = price_row.css('td')[4].text.gsub(/,/,"").to_f
			row_vol   = price_row.css('td')[6].text.gsub(/,/,"").to_f
			p "date=#{Time.at(row_date)}, o=#{row_open}, h=#{row_high}, l=#{row_low}, c=#{row_close}, v=#{row_vol}"
			ps =
			Priceseries.new(
				ticker: ticker.to_s,
				name: name,#名前をスクレイピングして取得するのも良い
				open: row_open,
				high: row_high,
				low: row_low,
				close: row_close,
				volume: row_vol,
				ymd: row_date)
			ps.save
		end
	end
  def getPriceKabutan(ticker)
  	url_price = "https://kabutan.jp/stock/kabuka?code=#{ticker.to_s}"

		doc = ApplicationController.new.getDocFromHtml(url_price)
		if doc.nil?
			return
		end
    # 名前:nameを取得する→<td width="184" class="kobetsu_data_table1_meigara">日産自動車</td>
    name = doc.css(".kobetsu_data_table1_meigara").text

		p "ticker = #{ticker.to_s}, name=#{name.to_s}"


		# 最新データの取得
		price0 = doc.css(".stock_kabuka0 > tr")
		if (price0.nil?) | (price0.count==0)
			p "最新株価が存在しないのでスルーします"
			return
		end

		# 株価データが存在すれば古いデータは削除する
		if Priceseries.where(ticker: ticker.to_s).count > 0 #該当ticker時系列データを削除したらこのくだりは不要かも
			Priceseries.where(ticker: ticker.to_s).delete_all
			if false
				newest_ymd = Time.at(Priceseries.where(ticker: ticker.to_s).order(ymd: :desc).last.ymd)
				today_ymd = Date.today.in_time_zone('Tokyo')#最新日付
				p "new=#{newest_ymd}, today = #{today_ymd}"
				# if Priceseries.where(ticker: ticker.to_s).where(Priceseries.arel_table[:ymd].gteq(today_ymd)) == 0
				if today_ymd > newest_ymd
					p "すでに最新のデータを反映済みです"
					# 最新データ(当日株価)だけは取得していないので取得する仕組み必要かも。
					return
				end
			end
		end
		td_tags = price0.css('td')
		target_date = td_tags[0].nil? ? "" : (td_tags[0]).text
		target_year = "20" + target_date[0..1].to_s
		target_month = target_date[3..4].to_s
		target_day = target_date[6..7].to_s
		# target_ymd = (target_year.to_s+target_month.to_s+target_day.to_s).to_i
		target_ymd = Date.new(target_year.to_i, target_month.to_i, target_day.to_i).in_time_zone('Tokyo')
		start_value = (td_tags[1].nil? ? "" : (td_tags[1]).text).gsub(/,/, "").to_f
		high_value = (td_tags[2].nil? ? "" : (td_tags[2]).text).gsub(/,/, "").to_f
		low_value = (td_tags[3].nil? ? "" : (td_tags[3]).text).gsub(/,/, "").to_f
		end_value = (td_tags[4].nil? ? "" : (td_tags[4]).text).gsub(/,/, "").to_f
		vol_value = (td_tags[7].nil? ? "" : (td_tags[7]).text).gsub(/,/, "").to_f
		p "#{target_year} , #{target_year}, #{target_month}, #{target_day}, #{start_value}"
		ps =
		Priceseries.new(
			ticker: ticker.to_s,
			name: name,#名前をスクレイピングして取得するのも良い
			open: start_value,
			high: high_value,
			low: low_value,
			close: end_value,
			volume: vol_value,
			ymd: target_ymd)
		ps.save


  	price_series = doc.css(".stock_kabuka1 > tr")
		if (price_series.nil?) | (price_series.count==0)
			p "株価の時系列データが存在しないのでスルーします"
			return
		end
  	price_series.each do |record|
  		# 最初の1個目はth(table header), 2個目以降がtd(data)
  		td_tags = record.css('td')
  		if !td_tags# thの場合
  			th_tags = record.css('th')
        p th_tags
  			th_tags.each do |th|
  				p th.text
  			end
  		else
        if td_tags.count > 0
          # 日付
          target_date = td_tags[0].nil? ? "" : (td_tags[0]).text
          target_year = "20" + target_date[0..1].to_s
          target_month = target_date[3..4].to_s
          target_day = target_date[6..7].to_s
          # target_ymd = (target_year.to_s+target_month.to_s+target_day.to_s).to_i
					target_ymd = Date.new(target_year.to_i, target_month.to_i, target_day.to_i).in_time_zone('Tokyo')

          # 始値
          start_value = (td_tags[1].nil? ? "" : (td_tags[1]).text).gsub(/,/, "").to_f
          # 高値
          high_value = (td_tags[2].nil? ? "" : (td_tags[2]).text).gsub(/,/, "").to_f
          # 安値
          low_value = (td_tags[3].nil? ? "" : (td_tags[3]).text).gsub(/,/, "").to_f
          # 終値
          end_value = (td_tags[4].nil? ? "" : (td_tags[4]).text).gsub(/,/, "").to_f
          # 出来高
          vol_value = (td_tags[7].nil? ? "" : (td_tags[7]).text).gsub(/,/, "").to_f
  				Priceseries.new(
    				ticker: ticker.to_s,
            name: name,#名前をスクレイピングして取得するのも良い
    				open: start_value,
    				high: high_value,
    				low: low_value,
    				close: end_value,
    				volume: vol_value,
    				ymd: target_ymd).save
        end
  		end
  	end
  end
	def getYahooTicker
		# yahoo finance自体の株価指数がない場合は全てMSCIで取得する？
		return [
			'^DJI', # Dow Jones Industrial Index
			'AAPL',#apple
			'FB',
			'AMZN',#amazon
			# '^GSPC',# :SP500
			# '^IXIC', # :NASDAQ
			'^JKSE', #jakarta->used
		  "EZA", # code:"ZA"},#SouthAfrica->used
		  "ERUS", # code:"RU"},#russia->used
		  "^BVSP", # code:"BR"},#brazil->used
		  "^GSPTSE", # code:"CA"},#canada->used
		  "^AORD", # code:"AU"},#australia->used
		  "^KS11", # code:"KR"},#korea->used
		  "^TWII", # code:"TW"},#taiwan->used
	    # "DAX", # code:"DE"},#German->no use
			"EWQ", #France->used
		  "^FTSE?P=FTSE", # code:"GB"},#FTSE all->used
		  "^HSI", # code:"CN"},#HangSengIndex->used
		  "^NZ50", # code:"NZ"},#NewZealand->used
		  "^AXJO", # code:"AT"},#->used
		  "EWS", # code:"SG"}, #singapore->used
		  "^GDAXI", # code:"DE"},#german->used
		  "EWI", # code:"IT"},->used
		  "^MERV", # code:"AR"},->used
		  "^MXX", # code:"MX"},->used
		  "EWM", # code:"MY"},->used
		  "MCHI", # code: "CH"}, #->used
			"EGPT"  #EGYPT -> used
		]
	end
	# nk225個別銘柄と指数値、ドル円,上海総合指数、ユーロ円のticker一覧を取得する
	def getKabutanTicker
		# 本来的には225銘柄を自動で取得する必要あるかも
		#コピペで取得したコード一覧(excel自体は保存してないが上記サイトをコピペして手動＆式でコードを連結したもの)

		# 以下から取得する
		# https://indexes.nikkei.co.jp/nkave/index/component?idx=nk225
		nikkei_codes= []
		nikkei_codes.push("0000") # 日経株価指数
		nikkei_codes.push("0823") # 上海総合指数
		nikkei_codes.push("0950") # ドル円
		nikkei_codes.push("0951") # ユーロ円

		url_nikkei = "https://indexes.nikkei.co.jp/nkave/index/component?idx=nk225"
		doc = ApplicationController.new.getDocFromHtml(url_nikkei)
		if !doc.nil?
			doc.xpath('//div[@class="col-xs-3 col-sm-1_5"]').each do |each_row|
				if each_row.text == 'コード'
					next
				end
				nikkei_codes.push(each_row.text)
			end
		end

		return nikkei_codes
	end
end
