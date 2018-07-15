# 世界の株価動向を一覧・一目で見れる
# 値上がり傾向、値下がりトップ５


require 'yahoo-finance'
require 'uri'

#scrape255:
require 'nokogiri'
require 'open-uri'


namespace :db do
	desc "Fill database with sample data"
	task updatePrice: :environment do

		arrCode = get225code()
    # 一気に250銘柄進めようとすると負荷をかけてしまうためまずい→updated_atを見ながら当日取得していない銘柄を5銘柄ずつくらい取得する
    arrCode.each do |code|
			ticker_without_t = code.gsub(/-T/, '').to_s
      getPriceKabutan(ticker_without_t)

    end
		arrCode = getYahooTicker()
		arrCode.each do |code|
			getPriceYahoo(code)
		end
	end

	def isValidate(url_string, limit = 10)
		begin
	    response = Net::HTTP.get_response(URI.parse(URI.encode(url_string)))
	  rescue
			p "error"
	    return false
	  else
	    case response
	    when Net::HTTPSuccess
				p "success"
	      return true
	    when Net::HTTPRedirection
				p "redirect"
	      isValidate(response['location'], limit - 1)
	    else
	      return false
	    end
	  end

		return true
	end

	# string型のurlからhtmlを取得する
	def getDocFromHtml(url_string)


		if !isValidate(URI.encode(url_string))
			p "そのURLは無効です"
			return nil;
		end


		url_encoded = URI.encode(url_string)
  	charset = nil
  	html = open(url_encoded) do |f|
  		charset = f.charset # 文字種別を取得
  		f.read # htmlを読み込んで変数htmlに渡す
  	end
  	doc = Nokogiri::HTML.parse(html, nil, charset)
		return doc
	end

  # k-dbサービス終了に伴い、別の方法を検討
  # 日経銘柄：kabutan
  # dji : https://finance.yahoo.com/quote/%5EDJI/history?p=%5EDJI
  # sp5 : https://finance.yahoo.com/quote/%5EGSPC/history?p=%5EGSPC
  # gld : https://finance.yahoo.com/quote/GC=F?p=GC=F
	def getPriceYahoo(ticker)
		# url_price = "https://finance.yahoo.com/quote/%5EDJI/history?p=%5EDJI"
		url_price = "https://finance.yahoo.com/quote/#{ticker.to_s}/history?p=#{ticker.to_s}"
		p url_price
		doc = getDocFromHtml(url_price)

		if doc.nil?
			return
		end


		# name = doc.css("#D(ib)")
		# Nokogiri::CSS::SyntaxError: unexpected
		# doc.xpath('//div[@class="thumb-block "]').each do |node|
		# name  = doc.xpath('//div')
		name = doc.css("h1").text
		# price_datas = doc.xpath('//tbody[@data-reactid="50"')
		# price_datas = doc.xpath(".//div[@id='app'")
		price_datas = doc.css('tbody')[0].css('tr')
		# すでにあれば削除する
		if price_datas.count > 0
			if Priceseries.where(ticker: ticker.to_s).count > 0
				Priceseries.where(ticker: ticker.to_s).delete_all
			end
		end
		price_datas.each do |price_row|
				# Date, Open, High, Low, Close, Volume
				row_date  = Date.parse(price_row.css('td')[0].text).to_time.in_time_zone('Tokyo').to_i#to_iでunix_time変換
				row_open  = price_row.css('td')[1].text.gsub(/,/,"").to_f
				row_high  = price_row.css('td')[2].text.gsub(/,/,"").to_f
				row_low   = price_row.css('td')[3].text.gsub(/,/,"").to_f
				row_close = price_row.css('td')[4].text.gsub(/,/,"").to_f
				row_vol   = price_row.css('td')[5].text.gsub(/,/,"").to_f
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

		doc = getDocFromHtml(url_price)
		if doc.nil?
			return
		end
    # 名前:nameを取得する→<td width="184" class="kobetsu_data_table1_meigara">日産自動車</td>
    name = doc.css(".kobetsu_data_table1_meigara").text

		p "ticker = #{ticker.to_s}, name=#{name.to_s}"
		# 時系列の最新日付がDB保存データよりも大きいならば更新:https://qiita.com/Kta-M/items/8bd941d3f61a536e21ac
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

		# 最新データの取得
		price0 = doc.css(".stock_kabuka0 > tr")
		if (price0.nil?) | (price0.count==0)
			p "最新株価が存在しないのでスルーします"
			return
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

          p "#{ticker.to_s},start:#{start_value},high:#{high_value},low:#{low_value},end:#{end_value},vol:#{vol_value},#{target_ymd}"
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
		return [
			'^DJI', # Dow Jones Industrial Index
			'^GSPC',# :SP500
			'^IXIC' # :NASDAQ
		]
	end
	# nk225個別銘柄と指数値、ドル円,上海総合指数、ユーロ円のticker一覧を取得する
	def getKabutanTicker
		# 本来的には225銘柄を自動で取得する必要あるかも
		#コピペで取得したコード一覧(excel自体は保存してないが上記サイトをコピペして手動＆式でコードを連結したもの)
		return [
			# 日経,ドル円,上海総合,ユーロ円
			'0000','0950','0823','0951',
			'9532','9531','9503','9502','9501','9301','9202','9107','9104','9101','9064','9062','9022',
			'9021','9020','9009','9008','9007','9005','9001','8830','8804','8802','8801','3289','7951',
			'7912','7911','7012','7003','7013','7011','7004','6473','6472','6471','6367','6366','6361',
			'6326','6305','6302','6301','6113','6103','5631','1963','1928','1925','1812','1808','1803',
			'1802','1801','1721','8058','8053','8031','8015','8002','8001','2768','5901','5803','5802',
			'5801','5715','5714','5713','5711','5707','5706','5703','3436','5541','5413','5411','5406',
			'5401','5333','5332','5301','5233','5232','5214','5202','5201','5108','5101','5020','5002',
			'6988','4911','4901','4452','4272','4208','4188','4183','4063','4061','4043','4042','4021',
			'4005','4004','3407','3405','3865','3863','3861','3402','3401','3103','3101','1605','9766',
			'9735','9681','9602','4755','4704','4689','4324','2432','9983','8267','8252','8233','8028',
			'3382','3099','3086','2914','2871','2802','2801','2531','2503','2502','2501','2282','2269',
			'2002','1333','1332','8795','8766','8750','8729','8725','8630','8628','8604','8601','8253',
			'8411','8355','8354','8331','8316','8309','8308','8306','8304','8303','7186','9984','9613',
			'9437','9433','9432','9412','7762','7733','7731','4902','4543','7272','7270','7269','7267',
			'7261','7211','7205','7203','7202','7201','8035','7752','7751','7735','6976','6971','6954',
			'6952','6902','6857','6841','6773','6770','6762','6758','6752','6703','6702','6701','4151',
			'6674','6508','6506','6504','6503','6502','6501','6479','3105','4568','4523','4519','4507',
			'4506','4503','4502']
	end
end
