# PriceNewest(id: integer, ticker: string, pricetrade: float, datetrade: integer, ask: float, bid: float, created_at: datetime, updated_at: datetime)

class PriceNewestController < ApplicationController
  def index

    # ticker = ["USDJPY=X", "EURJPY=X"];
    ticker = ["USDJPY=X", "EURJPY=X", "^N225", "^DJI", "000001.SS"];

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
    # p "data = #{yahoodata}"

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
