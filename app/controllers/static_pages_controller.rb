# モデル構造：最新断面(Pricenewest)と時系列データ(Priceseries)の二つ取得
# >ActiveRecord::Base.connection.tables


# デザイン
# http://w-finder.com/cool
# http://photoshopvip.net/archives/17887

# リアルタイム機能
# http://blog.mlkcca.com/backend/milkcocoa-for-ror/


# historical currency data取得
# http://stackoverflow.com/questions/3139879/how-do-i-get-currency-exchange-rates-via-an-api-such-as-google-finance?rq=1
# http://stackoverflow.com/questions/28918968/how-to-get-historical-data-for-currency-exchange-rates-via-yahoo-finance

require 'yahoo-finance'

# nikkeiから値上がり率ランキング取得
require 'open-uri'# URLアクセス
require 'kconv'    # 文字コード変換
require 'nokogiri' # スクレイピング
require 'time'
require 'date'


# for btitcoin
require 'net/http'
require 'uri'
require 'json'

class StaticPagesController < ApplicationController

  # 以下各ページに限定したニュースフィードだけでいいかも。
  # feedsモデルにカテゴリを追加→とりあえず最初はすべてのニュースで良い
  def nikkei

    # p "count = " + @events.count
    # @up_ranks = get_rank_hash("priceup")
    # @down_ranks = get_rank_hash("pricedown")
    @up_ranks = get_rank_from_db("priceup")
    @down_ranks = get_rank_from_db("pricedown")

    p "uprank = #{@up_ranks}"
    p "downrank = #{@down_ranks}"

    # @nikkei225_now2 = Priceseries.find_by_sql("select * from Priceseries where ticker = '^N225' order by ymd desc limit 2")
    @nikkei225_now2 = Priceseries.where(ticker: "^N225").order(ymd: :asc).limit(2)


    gon.historical_data=#Priceseries.all.order(:ymd)
    Priceseries.where(ticker: "^N225").order(ymd: :asc)
    # Priceseries.find_by_sql("select * from priceseries where ticker = '^N225' order by 'ymd' desc")
    p "nikkei225"
    p gon.historical_data.length

    if @nikkei225_now2.length == 2
      todayVal = @nikkei225_now2[0].close.to_f
      yesterdayVal = @nikkei225_now2[1].close.to_f
      @returnNikkei225 = sprintf("%.2f", ((todayVal / yesterdayVal - 1.0)*100.0).to_f).to_s + "%"
      @diffNikkei225 = sprintf("%.2f", (todayVal - yesterdayVal))
      @valueNikkei225 = todayVal
    end
  end

  def dow
    # b = 13754.4566
    # print number_with_delimiter(b, :delimiter => ',')


    gon.dow_historical=#Priceseries.all.order(:ymd)
    Priceseries.where(ticker: "^DJI").order(ymd: :asc)
    # Priceseries.find_by_sql("select * from priceseries where ticker = '^DJI' order by 'ymd' desc")

    @dow_now2 =
    Priceseries.where(ticker: "^DJI").order(ymd: :asc).limit(2)
    # Priceseries.find_by_sql("select * from Priceseries where ticker = '^DJI' order by ymd desc limit 2")
    p "shanghai"
    p @dow_now2[0].close.to_f
    p @dow_now2[1].close.to_f
    if @dow_now2.length == 2
      @valuedow = @dow_now2[0].close.to_f
      yesterdayVal = @dow_now2[1].close.to_f
      @returndow = sprintf("%.2f", ((@valuedow / yesterdayVal - 1.0)*100.0).to_f).to_s + "%"
      @diffdow = sprintf("%.2f", (@valuedow - yesterdayVal))
    end



  end

  def shanghai

    gon.shanghai_historical=#Priceseries.all.order(:ymd)
    Priceseries.where(ticker: "000001.SS").order(ymd: :asc)
    # Priceseries.find_by_sql("select * from priceseries where ticker = '000001.SS' order by 'ymd' desc")

    @shanghai_now2 =
    #Priceseries.find_by_sql("select * from Priceseries where ticker = '000001.SS' order by ymd desc limit 2")
    Priceseries.where(ticker: "000001.SS").order(ymd: :asc).limit(2)
    p "shanghai"
    p @shanghai_now2[0].close.to_f
    p @shanghai_now2[1].close.to_f
    if @shanghai_now2.length == 2
      @valueShanghai = @shanghai_now2[0].close.to_f
      yesterdayVal = @shanghai_now2[1].close.to_f
      @returnShanghai = sprintf("%.2f", ((@valueShanghai / yesterdayVal - 1.0)*100.0).to_f).to_s + "%"
      @diffShanghai = sprintf("%.2f", (@valueShanghai - yesterdayVal))
    end


    # p "shanghai_historical = #{gon.shanghai_historical.length}"
    # gon.shanghai_historical.each do |sh|
    #   p sh
    # end



    # http://nikkei225jp.com/china/
    # 中国上海アジア市場のスクレイピング
    @arrIndices =
    ["上海総合指数 中国",
     "CSI300指数 中国",
     "上海Ｂ株 中国",
     "深センＢ株 中国",
     "上海Ａ株 中国",
     "深センＡ株 中国",
     "HangSeng 香港",
     "H株指数 香港",
     "レッドチップ指数 香港",
     "韓国",
     "加権 台湾",
     "為替 ドル円",
     "為替 ドル元",
     "ユーロ元"]
     arrIndexTickers =
     ["000001.SS",#上海総合指数 中国
      "000300.SS",#CSI300指数 中国
      "000003.SS",#上海Ｂ株 中国
      "399108.SZ",#深センＢ株 中国
      "000002.SS",#上海Ａ株 中国
      "399107.SZ",#深センＡ株 中国
      "^HIS",#HangSeng 香港
      "^HSCE",#H株指数 香港
      "^HSCC",#レッドチップ
      "^KS11",#韓国
      "^TWII",#台湾
      "USDJPY=X",#ドル円
      "USDCNY=X",#ドル元
      "EURCNY=X"#ユーロ元
    ]
    # 二つの配列からhashを作成する
    ary = [arrIndexTickers,@arrIndices].transpose
    @hash_key_name_asia = Hash[*ary.flatten]
    arrActiveRecord =  PriceNewest.where(ticker: arrIndexTickers).order(datetrade: :desc)
    # p "count = " + arrActiveRecord.count.to_s + "," + @arrIndices.count.to_s
    # @asia_newest_dataをarrIndicese(arrIndexTickers)と同じ並び順でデータを格納する
    @asia_newest_data = []
    arrIndexTickers.each do |ticker|
      # p ticker
      arrActiveRecord.each do |record|
        if record.ticker == ticker
          @asia_newest_data.push(record)
          # p @asia_newest_data.last.ticker
          break
        end
      end
    end
    # example
    # p "newest = " + @asia_newest_data[0].ticker.to_s
    # p "newest = " + @asia_newest_data[0].pricetrade.to_s
    # p "newest = " + @asia_newest_data[0].previoustrade.to_s
    # p "newest = " + @asia_newest_data[1].ticker.to_s

    cnt = 0
    @asia_newest_data.each do |asia|
      p asia.ticker.to_s + "(" + asia.pricetrade.to_s + ")" +asia.datetrade.to_s +
        @arrIndices[cnt]
      cnt = cnt + 1
    end



  end
  def europe


    gon.europe_historical=#Priceseries.all.order(:ymd)
    Priceseries.where(ticker: "^FTSE").order(ymd: :asc)
    # Priceseries.find_by_sql("select * from priceseries where ticker = '^FTSE' order by 'ymd' desc")
    @europe_now2 =
    Priceseries.where(ticker: "^FTSE").order(ymd: :asc).limit(2)
    # Priceseries.find_by_sql("select * from Priceseries where ticker = '^FTSE' order by ymd desc limit 2")
    p "shanghai"
    p @europe_now2[0].close.to_f
    p @europe_now2[1].close.to_f
    if @europe_now2.length == 2
      @valueEurope = @europe_now2[0].close.to_f
      yesterdayVal = @europe_now2[1].close.to_f
      @returnEurope = sprintf("%.2f", ((@valueEurope / yesterdayVal - 1.0)*100.0).to_f).to_s + "%"
      @diffEurope = sprintf("%.2f", (@valueEurope - yesterdayVal))
    end
  end
  def commodity

  end
  def bitcoin
    # bitcoinに限定したニュースだけでいいかも


    # http://bitcoin.stackexchange.com/questions/32558/api-feed-for-ohlc-vwap-data-in-close-to-real-time
    gon.historical_btc =
    Priceseries.where(ticker: "btci").order(ymd: :asc)
    # Priceseries.find_by_sql("select * from priceseries where ticker = 'btci' order by 'ymd' desc")

    @btc_now2 =
    Priceseries.where(ticker: "btci").order(ymd: :asc).limit(2)
    # Priceseries.find_by_sql("select * from Priceseries where ticker = 'btci' order by ymd desc limit 2")
    if @btc_now2.length == 2
      @valueBtc = @btc_now2[0].close.to_f
      yesterdayVal = @btc_now2[1].close.to_f
      @returnBtc = sprintf("%.2f", ((@valueBtc / yesterdayVal - 1.0)*100.0).to_f).to_s + "%"
      @diffBtc = sprintf("%.2f", (@valueBtc - yesterdayVal))
    end




    # 難易度などのテーブル取得
    # http://bitcoincharts.com/markets/coinbaseUSD.html

    url = "http://bitcoincharts.com/markets/coinbaseUSD.html"
    html = open(url) do |f|
      f.read # htmlを読み込んで変数htmlに渡す
    end
    doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')
    rank_all = Hash.new
    p "start"
    @hash_fundamentals = Hash.new
    doc.xpath('//body[@class=""]/div[@id="header"]/div[@class="container_12"]')
      .xpath('div[@class="networkinfo grid_8 right"]').children.each do |content|

      if content.xpath('table/tr').count > 0
        content.xpath('table/tr').each do |row|
          key = row.xpath('td')[0].inner_html
          value = row.xpath('td')[1].inner_html
          @hash_fundamentals[key] = value
        end
      end
    end


    # ここからfetch_controller
    # ビットコインニュース
    # url = "http://btcnews.jp"
    # html = open(url) do |f|
    #   f.read # htmlを読み込んで変数htmlに渡す
    # end
    # doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')
    # rank_all = Hash.new
    # @bitcoinNews = []
    # doc.xpath('//article').each do |article|
    #   # p "article:" + article.inner_html
    #   title = article.xpath('a').attribute('title').value
    #   url = article.xpath('a').attribute('href').value
    #   entry_date = article.xpath('div[@class="feat-meta"]/span[@class="feat_time entry-date"]').inner_html
    #
    #   p "#{title}, #{entry_date}"
    #   # <span class="feat_time entry-date"><abbr class="published" title="2016-04-21T18:32:25+00:00">2016年4月21日</abbr></span>
    #
    #   # published = article.xpath('div[@class="feat-meta"]/span[@class="feat_time entry-date"]')
    #   # p published.children
    #   # published.children.each do |child|
    #   #   p "a " + child.attribute("title").to_s
    #   # end
    #   published = nil
    #   article.xpath('div[@class="feat-meta"]/span[@class="feat_time entry-date"]').children.each do |child|
    #     p "pattern A"
    #     published = child.attribute("title").to_s
    #   end
    #   if published == nil || published.equal?("") then
    #     p "pattern B"
    #     article.xpath('div[@class="feat-right"]/div[@class="feat-meta"]/span[@class="feat_time entry-date"]').children.each do |child|
    #       published = child.attribute('title').to_s
    #     end
    #   end
    #
    #   if published == nil || published.equal?("") then
    #     # 本当はpublishedなしでも適当に日付設定して保存したい
    #     p "publishedなし #{title}, #{url}, #{entry_date}"
    #   else
    #     p "published = #{published}"
    #
    #     hash = Hash.new
    #     hash["title"] = title
    #     hash["url"] = url
    #     hash["entry_date"] = entry_date
    #     #transform
    #     # from "published"=>"2016-04-19T12:00:41+00:00"
    #     # to 2016-02-17 02:42:05(Feed.created_at form)
    #     years    =    published[0, 4].to_i
    #     months   =    published[5, 2].to_i
    #     dates    =    published[8, 2].to_i
    #     hours    =    published[11,2].to_i
    #     minutes  =    published[14,2].to_i
    #     seconds  =    published[17,2].to_i
    #     p "#{years}, #{months}, #{dates}, #{hours}, #{minutes}, #{seconds}"
    #     published_datetime =
    #     Time.local(years, months, dates,
    #                hours, minutes, seconds)
    #     p "#{published_datetime.to_i} : #{title}"
    #     hash["published"] = published_datetime
    #     @bitcoinNews[@bitcoinNews.count + 1] = hash
    #   end
    # end
    #
    # url = "https://news.bitcoin.com/"
    # html = open(url) do |f|
    #   f.read # htmlを読み込んで変数htmlに渡す
    # end
    # doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')
    # rank_all = Hash.new
    # doc.xpath('//div[@class="td_module_12 td_module_wrap td-animation-stack"]').each do |article|
    #   # title
    #   title = article.xpath('div[@class="item-details"]/h3[@class="entry-title td-module-title"]/a').inner_text
    #   # time
    #   published = article.xpath('div[@class="item-details"]/div[@class="meta-info"]/div[@class="td-post-date"]/time').attribute("datetime").value
    #   # link
    #   url = article.xpath('div[@class="item-details"]/h3[@class="entry-title td-module-title"]/a').attribute("href").value
    #   hash = Hash.new
    #   hash["title"] = title
    #   hash["url"] = url
    #   #transform
    #   # from "published"=>"2016-04-19T12:00:41+00:00"
    #   # to 2016-02-17 02:42:05(Feed.created_at form)
    #   years    =    published[0, 4].to_i
    #   months   =    published[5, 2].to_i
    #   dates    =    published[8, 2].to_i
    #   hours    =    published[11,2].to_i
    #   minutes  =    published[14,2].to_i
    #   seconds  =    published[17,2].to_i
    #   published_datetime =
    #   Time.local(years, months, dates,
    #              hours, minutes, seconds)
    #   hash["published"] = published_datetime
    #   @bitcoinNews[@bitcoinNews.count + 1] = hash
    # end
    # ここまでfetch
    @bitcoinNews = Feed.tagged_with("bitcoin")


    # 本番データに入れる時にはFeedsモデルに格納する(keyは臨機応変に修正)
    p @bitcoinNews


  end

  def adr
    @hash_adr = {
      :SNE => "6758.T",
      :CAJ => "7751.T",
      :ATE => "6857.T",
      :NJ  => "6594.T",
      :KYO => "6971.T",
      # :KNM => "",
      :TM  => "4704.T",
      :HMC => "7267.T",
      :NTT => "9432.T",
      :DCM => "9437.T",
      # :IIJI=> "",
      # :UBIC=> "",
      # :MFJ => "",
      :MTU => "8306.T",
      :SMFG=> "8316.T",
      :NMR => "8604.T",
      :IX  => "8591.T"}

    # adr一覧を取得する
    @adr_all = Adr.all
    @adr_all.each do |adr|
      p "#{adr.ticker}, #{adr.tcode}"
    end
  end
  def fx
    @usdjpy =
    PriceNewest.where(ticker: "USDJPY=X").order(datetrade: :desc).limit(1)[0]
    # PriceNewest.find_by_sql(
    # "select * from price_newests where ticker = 'USDJPY=X' order by 'datetrade' desc")[0]
    @eurjpy =
    PriceNewest.where(ticker: "EURJPY=X").order(datetrade: :desc).limit(1)[0]
    # PriceNewest.find_by_sql(
    # "select * from price_newests where ticker = 'EURJPY=X' order by 'datetrade' desc")[0]
    # if @usdjpy && @eurjpy
    #   p "usdjpy = #{@usdjpy.datetrade}"
    #   p "usdjpy = #{@usdjpy.ask}"
    #   p "eurjpy = #{@eurjpy}"
    #   p "fx = #{@usdjpy.datetrade}"
    # end

    # hashにして全通貨の組み合わせを格納
    @hash_fx = Hash.new
    @hash_fx["date"] = @usdjpy.datetrade
    @arr_keys = Array.new

    PriceNewest.where(datetrade: @usdjpy.datetrade).each do |pricenewest|
      @hash_fx[pricenewest.ticker] = pricenewest.pricetrade
      # p "hash_fx:#{pricenewest.ticker} = #{@hash_fx[pricenewest.ticker]}"
      # p @arr_keys.include?(pricenewest.ticker.first(3))
      unless @arr_keys.include?(pricenewest.ticker.first(3))
        if pricenewest.ticker.last(2) == "=X"
          @arr_keys.push((pricenewest.ticker).first(3))
          # p "push => #{(pricenewest.ticker).first(3)}"
        end
      # else
        # p "exists => #{pricenewest.ticker.first(3)}"
      end
    end

    # @hash_fx.each do |hash|
    #   p "hash_fx = #{hash}"
    # end
    #
    # p "length = #{@arr_keys.count}"
    # @arr_keys.each do |key|
    #   p "key = #{key}"
    # end


  end
  def portfolio
  end
  def kessan
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


    # test用に出力するメソッド（tickerの確認など..)
    get_fx_index#fx取得のみ

    gon.user_name="historical data"

    # try and error->本来的にはfind_by(ymd: 20160101, ticker:"^N225")などとするのが適切（以下はテスト）
    gon.historical_data=
    Priceseries.where(ticker: "^N225").order(ymd: :asc)
    # Priceseries.find_by_sql("select * from priceseries where ticker = '^N225' order by 'ymd' desc")

  end

  def help
  end

  def get_fx_index#(ticker)
    p "get_fx_index"
    # 銘柄コード調べ方その２＝＞yahoo finance shanghaiとググってyahoo financeのページに表示された（それらしい）インデックス
    # http://finance.yahoo.com/q?s=%5EN225
    # http://finance.yahoo.com/q?s=000001.SS
    # yahoo_client = YahooFinance::Client.new
    # datas = yahoo_client.historical_quotes("000001.SS", { start_date: Time::now-(24*60*60*4), end_date: Time::now})
    # datas = yahoo_client.historical_quotes("USDJPY=FX", { start_date: Time::now-(24*60*60*4), end_date: Time::now})
    # datas = yahoo_client.quotes("USDJPY=X", [:ask, :bid, :last_trade_date])


    yahoo_client = YahooFinance::Client.new
    datas = yahoo_client.quotes(["USDJPY=X"], [:ask, :bid, :last_trade_date])

    p datas
  end


  def get_currency
    p "get_currency"
    if !@usdjpy#一度取得しても再度開くときは再取得する仕組みになってしまう
      yahoo_client = YahooFinance::Client.new
      @usdjpy = yahoo_client.quotes(["USDJPY=X"], [:ask, :bid, :last_trade_date])
      p @usdjpy
    end

    p "return"
  end

  def get_rank_from_db(priceUpOrDown)
    sort = priceUpOrDown
    if priceUpOrDown == "priceup"
      sort = "up"
    elsif priceUpOrDown == "pricedown"
      sort = "down"
    else
      return
    end

    rank_all = Hash.new
    (1..30).each do |rank|
      p rank
      rank_info = Hash.new
      rankModel = Rank.find_by(
      market: "^N225",
      rank: rank,
      sort: sort
      )

      if !rankModel
        next
      end
      # p rankModel.id
      # p rankModel.stock_code
      # p rankModel.name



      # p "code = "  + rankModel["stock_code"].to_s
      # p "name = " + rankModel["name"].to_s
      # p "nowprice = " + rankModel["nowprice"].to_s

      if rank
        rank_info["rank"] = rank
      end
      if rankModel.stock_code
        rank_info["stock_code"] = rankModel.stock_code
      end
      if rankModel.name
        rank_info["name"] = rankModel.name
      end
      if rankModel.nowprice
        rank_info["price"] = rankModel.nowprice
      end
      if rankModel.vsYesterday
        # rank_info["vsYesterday"] = rankModel.changeprice
        rank_info["vsYesterday"] = rankModel.vsYesterday
      end
      if rankModel.return
        rank_info["return"] = rankModel.return
      end


      # :market          => "^N225",
      # :stock_code      => stock_code,
      # :rank            => rank,
      # :name            => name,
      # :sort            => upOrDown,
      # :changerate      => ret,

      # :nowprice        => price

      rank_all[rank] = rank_info


    end


    return rank_all
  end

  # RanksControllerで実施済（定期実行予定）
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


  # 整数をカンマ区切りにする
  #  http://qiita.com/Katsumata_RYO/items/1055c2f27cbd99e67fc2
  # def jpy_comma
  #  self.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
  # end

  def get_price_newest

    # ドル、ユーロ、英ポンド、ドイツマルク、フランスフラン、イタリアリラ、スイスフラン、中国元、ロシアルーブル
    cur = ["JPY", "USD", "EUR", "GBP", "DEM", "FRF", "ITL", "CHF", "CNY", "RUB"]
    ticker =[]
    no_cur = 0
    cur.each do |cur1|
      cur.each do |cur2|
        if cur1 != cur2
          ticker[no_cur]= String(cur1 + cur2 + "=X")
          p "no= #{no_cur}, ticker=#{ticker[no_cur]}"
          no_cur = no_cur + 1
        end
      end
    end
    ticker[ticker.length] = "^N225"
    ticker[ticker.length+1] = "^DJI"
    ticker[ticker.length+2] = "000001.SS"

    p "length = " + ticker.length.to_s


    # ticker = ["USDJPY=X", "EURJPY=X"];
#     ticker = [
#       "USDJPY=X", "EURJPY=X", "GBPJPY=X", "DEMJPY=X", "FRFJPY=X", "ITLJPY=X", "CHFJPY=X", "CNYJPY=X", "RUBJPY=X",
#        "^N225", "^DJI", "000001.SS"];
      #  http://www.oanda.com/convert/fxdaily?redirected=1&exch=JPY&format=HTML&dest=GET+CUSTOM+TABLE&sel_list=GBP_DEM_FRF_ITL_CHF_JPY_CNY_RUB_USD_EUR
      p "price_newest_controller = " + ticker.to_s
    # 今は最初のコードしか取得できていない


    # 将来的に別メソッドにする
    # get_yahoo_data(ticker)

    # yahooからtickerコードの最新情報を取得する
    yahoo_client = YahooFinance::Client.new
    yahoodata =
      yahoo_client.quotes(
        [ticker],#続けて取得する場合はカンマ区切りで配列にして渡すex. ["USDJPY=X, EURJPY=X"],
        [:last_trade_price, :ask, :bid, :last_trade_date])
    # yahoodata = yahoo_client.quotes(["USDJPY=X, EURJPY=X"])
    # p "ddddata = #{yahoodata}"

    i = 0;
    yahoodata.each do |ydata|

      p "ydata = #{ydata}, ticker = #{ticker[i]}"

      if ydata.last_trade_price == "N/A"
        p "データなし"
      else

        ask_usdjpy = ydata.ask.to_d
        bid_usdjpy = ydata.bid.to_d
        date_usdjpy = ydata.last_trade_date.to_s
        price_usdjpy = ydata.last_trade_price.to_d
        # test
        # date_usdjpy = "12/31/2014"


        # p "ask = #{ask_usdjpy}"
        # p "bid = #{bid_usdjpy}"
        # p "date = #{date_usdjpy}"
        # p "price = #{price_usdjpy}"
        # date_usdjpyをyyyymmdd形式に変換
        month = date_usdjpy.match(/\d*\//)[0].sub(/\//,"").to_i#最初の/の前の数字
        day = date_usdjpy.match(/\/\d*\//)[0].sub(/\//,"").sub(/\//,"").to_i#/**/で囲まれた数字
        year = date_usdjpy.match(/\/\d{4}/)[0].sub(/\//,"").to_i#/の後の４桁の数字
        # p "month = #{month}"
        # p "day = #{day}"
        # p "year = #{year}"

        date = Time.local(year, month, day, 10, 00, 00)
        # p "date = #{date.strftime('%Y%m%d')}"

        # DBに挿入
        insert_price_data(ticker[i],
         price_usdjpy,
          date.strftime('%Y%m%d'),
           ask_usdjpy, bid_usdjpy)

      end
      i = i + 1
    end
  end

  # パラメータdateはYYYYMMDDとする
  def insert_price_data(ticker, price, date, ask, bid)
    # PriceNewest(id: integer, ticker: string, pricetrade: float, datetrade: integer, ask: float, bid: float, created_at: datetime, updated_at: datetime)
    # [#<OpenStruct last_trade_price=\"113.9850\", ask=\"114.0000\", bid=\"113.9850\", last_trade_date=\"2/27/2016\", previous_trade_date=nil, previous_trade_price=nil>

    # すでにそのティッカーコードで同じ日付があれば取得しないようにする
    if !(PriceNewest.find_by(ticker: ticker, datetrade: date))
      pricedata = PriceNewest.new(
        :ticker           => ticker,
        :pricetrade       => price,
        :datetrade        => date,#ymd
        :ask              => ask,
        :bid              => bid
      )
      p "insert below.."
      p "ticker = #{pricedata.ticker}"
      p "pricetrade = #{pricedata.pricetrade}"
      p "datetrade = #{pricedata.datetrade}"
      p "ask = #{pricedata.ask}"
      p "bid = #{pricedata.bid}"
      pricedata.save
    else
      p "そのデータはすでに存在します=>#{PriceNewest.find_by(ticker: ticker, datetrade: date)}"
    end

  end
end
