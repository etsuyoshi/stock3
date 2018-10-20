require 'kconv'
class RankController < ApplicationController
  def index

    #ランキングを全て破棄して新しいランキングを取得する
    Rank.destroy_all

    #１日騰落率は日経のサイトからスクレイピングして取得する
    scrape_rank_hash('priceup')#東証一部
    scrape_rank_hash('pricedown')#東証一部


    #日経平均銘柄については３日平均、７日平均、１０日平均、３０日平均はPriceseriesから取得して更新する
    calc_rank_hash()
  end

  def calc_rank_hash()
    #Priceseriesから必要期間の株価データを取得して騰落率を計算(marketカラムには^N225-3days-returnや^N225-3days-changeなどとする)
    #まず３日騰落率から
    term_calc_array = [3, 7, 10, 30]
    term_calc_array.each do |term_calc|
      #term_calc=3
      market_column = "^N225-#{term_calc}days"
      return_market_column = "#{market_column}-return"
      change_market_column = "#{market_column}-change"

      #最新の日付を取得
      latest_ymd = Priceseries.where(ticker: "0000").first.ymd
      latest_tickers = Priceseries.where(ymd: latest_ymd).pluck(:ticker).uniq
      # time_latest_ymd = getTimeFromYMDHMS(latest_ymd.to_s+"000000")#00000は時分秒
      # ymd_Xdays_ago = (getYMDHMSFromTime(time_latest_ymd - (term_calc-1).days))[0..7].to_i
      ymd_Xdays_ago = latest_ymd - term_calc*24*3600


      # p latest_ymd
      # p ymd_Xdays_ago

      #X日前にも存在する全銘柄コードを取得
      all_tickers = Priceseries.where(ymd: ymd_Xdays_ago).where(ticker: latest_tickers).pluck(:ticker).uniq
      # all_tickers.each do |ticker|
      #   unless ticker[(ticker.length-2)..ticker.length]=="-T"#最後に-Tが付与されてなければ削除
      #     all_tickers.delete(ticker)
      #   end
      # end
      #最後の二文字が-Tでないものを削除
      # all_tickers.reject!{|ticker| ticker[ticker.length-2..ticker.length]!="-T"}
      info_all = Hash.new
      return_all = Hash.new#[[ticker1, return1], [ticker2,return2],..]
      change_all = Hash.new#[[ticker1, change1], [ticker2,return2],..]
      all_tickers.each_with_index do |ticker, i|
        if ticker.scan(/\D/).empty? #数字かどうか
          if ticker.to_i > 999 && ticker.to_i < 10000# ４桁の数字かどうか

            now_record = Priceseries.where(ymd: latest_ymd).where(ticker: ticker).first
            before_record = Priceseries.where(ymd: ymd_Xdays_ago).where(ticker: ticker).first
            return_price = (now_record.close.to_f / before_record.close.to_f - 1 ) * 100

            info = Hash.new
            #必要なデータは銘柄コード、名称、リターン、前日比、最新株価（後はランクを計算するだけ）
            #stock_code, name, return, vsYesterday, price
            info["name"] = now_record.name
            info["stock_code"] = now_record.ticker
            info["return"] = return_price
            info["vsYesterday"] = now_record.close.to_f - before_record.close.to_f
            info["price"] = now_record.close.to_f
            info_all[i] = info
            #騰落率ハッシュの設定
            #return_info = Hash.new
            #return_info[now_record.ticker] = info["return"]
            #return_all[i] = return_info
            return_all[now_record.ticker] = info["return"]


            #前日比ハッシュの入力
            # change_info = Hash.new
            # change_info[now_record.ticker] = info["vsYesterday"]
            # change_all[i] = change_info
            change_all[now_record.ticker] = info["vsYesterday"]
          end
        end
      end

      #info_allに全銘柄の騰落率や株価情報が取得できたら騰落率や下落幅のランキングを作成する(sort, reverse)

      #騰落率ランキング作成用のハッシュと幅ランキング作成用のハッシュを別々に作って以下の用にして一発で算出下腕、かくパラメータ（name, stock_code,priceなどを逆引きする方法の方がいいかも。）
      #http://kaorumori.hatenadiary.com/entry/20111015/1319278874
      return_all = return_all.sort_by{|ticker, value| value}#return_allをreturnでソートする（昇順）
      change_all = change_all.sort_by{|ticker, value| value}
      #上記配列をベースに上からと下から必要数の銘柄を獲得していく

      num_rank = [10, (return_all.length.to_i/2).to_i].min#上下必要なランキング数@return_allの合計が20未満なら半分ずつしか獲得する

      #上昇幅ランキング＆下落幅ランキング＆下落騰落率ランキング＆上昇騰落率ランキングのそれぞれに対して上昇、下落ランキングを取得する
      ranking_methods = ["return", "change"]
      ranking_formats = ["up","down"]
      ranking_methods.each_with_index do |ranking_method, i|
        #ランキング作成対象（騰落率か変化幅か）の選択
        survey_all = return_all
        if ranking_method == "return"
          survey_all = return_all
        elsif ranking_method == "change"
          survey_all = change_all
        else
          break
        end
        #昇順ランクと降順ランクのそれぞれに対して計算
        ranking_formats.each_with_index do |ranking_format, i|
          survey_all.each_with_index do |ret, i|
            #ランキング作成数の設定
            if i > num_rank
              break
            end
            #market = return_market_column
            market = return_market_column
            if ranking_method == "return"
              market = return_market_column
            else
              market = change_market_column
            end

            stockcode = ""
            if ranking_format == "down"
              stock_code = return_all[i][0]
            else
              stock_code = return_all[return_all.length - (i+1)][0]
            end
            rank = i+1
            name = ""
            no_info = 0
            info_all.each_with_index do |info, i|
              if info[1]["stock_code"] == stock_code
                name = info[1]["name"]
                no_info = i#info_allの中で何番目か
                break
              end
            end
            if name == ""
              break#info_allの中でstock_codeが見つからなければ実施しない
            end
            sort = ranking_format
            vsYesterday = info_all[no_info]["vsYesterday"]
            return_value = info_all[no_info]["return"]
            price = info_all[no_info]["price"]


            rankModel = Rank.new(
              :market          => market,
              :stock_code      => stock_code,
              :rank            => rank,
              :name            => name,
              :sort            => sort,
              :vsYesterday     => vsYesterday,
              :return          => return_value,
              :nowprice        => price
            )

            rankModel.save
          end
        end
      end
    end
  end

  def scrape_rank_hash(priceUpOrDown)
    p "scrape rank hash"
    if priceUpOrDown == 'priceup'
      p "値上がり上位"
    elsif priceUpOrDown == 'pricedown'
        p "値下がり上位"
    else
      return nil;
    end
    # url = "http://www.nikkei.com/markets/ranking/stock/" + priceUpOrDown.to_s + ".aspx"
    url = "https://www.nikkei.com/markets/ranking/page/?bd=" + priceUpOrDown.to_s
    doc = getDocFromHtml(url)
    if !doc
      p "urlが取得できませんでした→#{url}"
      return
    end

    # htmlをパース(解析)してオブジェクトを生成(utf-8に変換）
    # doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')
    rank_all = Hash.new

    doc.xpath('//table[@class="tblModel-1"]').xpath('tbody').xpath('tr').each do |content|
      #p "content = #{content}"
      # if content.xpath('tr').xpath('td').inner_text.to_i == 1
      #   p content.xpath('tr').xpath('td').xpath('a').inner_text
      # else
      #   p content.xpath('tr').xpath('td').xpath('a').inner_text
      # end

      rank_info = Hash.new
      rank = content.xpath('td[2]').inner_text.to_i

      if rank.kind_of?(Integer)
        rank2 = content.xpath('td[3]/a').inner_text #<- \r\tなどが含まれているので排除@rank_name
        stock_code = rank2[rank2.length-4,4]

        if stock_code
          rank_info["rank"] = rank
          #p "rank = #{rank}"
          rank_info["stock_code"] = stock_code
          #p "stock_code = #{stock_code}"
          #rank_info["name"] = content.xpath('td[4]/a').attribute("title").value
          rank_info["name"] = content.xpath('td[4]/a').inner_text
          #p "name = #{rank_info["name"]}"
          #騰落率は面倒なので自分で計算する
          # returnItem = content.xpath('td[5]').inner_text
          # #returnItem = returnItem.sub(/\r\n\r\n/,"").sub(/.*＋/,"").sub(/.*\−/,"")
          # returnItem = returnItem.sub(/\r\n\r\n/,"")
          # returnItem = returnItem[/\d+/].to_i#数字のみ抽出
          # rank_info["return"] =returnItem
          #p "return = #{returnItem}"
          priceItem = content.xpath('td[6]').inner_text
          priceItem = priceItem
          priceItem = priceItem.sub(/\r\n/,"").sub(/,/,"").sub(/\(.*/,"")[/[0-9]*\.?[0-9]+/]#余計なものを全部削除して最後に(小数点ありの)数字のみ抽出
          #http://stackoverflow.com/questions/694176/retrieve-number-from-the-string-pattern-using-regular-expression#
          p "priceItem = #{priceItem}"
          rank_info["price"] = priceItem

          vsYesterday = content.xpath('td[7]').inner_text
          #p "vsYesterday = #{vsYesterday}"
          #rank_info["vsYesterday"] = vsYesterday.match(/.*\r/)[0].sub(/\r/,"")#before version
          #rank_info["vsYesterday"] = vsYesterday[/\d+/].to_i#数字のみ抽出
          if priceUpOrDown == 'priceup'
            rank_info["vsYesterday"] = vsYesterday[/[0-9]*\.?[0-9]+/].to_f
          else
            rank_info["vsYesterday"] = -(vsYesterday[/[0-9]*\.?[0-9]+/].to_f)
          end
          rank_info["return"] = rank_info["vsYesterday"].to_f/(priceItem.to_f + rank_info["vsYesterday"].to_f)*100
          p rank_info

          rank_all[rank] = rank_info
        end

      end
    end

    # preserve_rank_array(rank_all, priceUpOrDown.downcase=='priceup' ? 'up' : 'down')
    # if priceUpOrDown.downcase == 'priceup'
    #   p "upppppppppppppppppp"
    #   preserve_rank_array(rank_all, "up")
    # elsif priceUpOrDown.downcase == 'pricedown'
    #   p "downnnnnnnnnnnnn"
    #   preserve_rank_array(rank_all, "down")
    # else
    #   p "指定エラー"
    # end

    # 取得したrank変数をRankモデルに保存する
    preserve_rank_array(rank_all, (priceUpOrDown.downcase=='priceup') ? 'up' : 'down')
  end

  def preserve_rank_array(rank_array, upOrDown)
    p "preserve_rank_array : #{rank_array} @#{upOrDown}"


    rank_array.each do |rank_item|
      rank = rank_item[1]["rank"]
      stock_code = rank_item[1]["stock_code"]
      name = rank_item[1]["name"]
      ret =  rank_item[1]["return"]
      diff = rank_item[1]["vsYesterday"]
      price = rank_item[1]["price"]

      # market:string
      # rank:integer
      # name:string
      # sort:string
      # changerate:float
      # changeprice:integer
      # nowprice:float
      p "rank = #{rank}"
      p "name = #{name}"
      p "sort = #{upOrDown}"
      p "changerate = #{ret}"
      p "changeprice = #{diff}"
      p "nowprice = #{price}"

      rankModel = Rank.new(
        :market          => "TOPIX",#TOPIX採用銘柄
        :stock_code      => stock_code,
        :rank            => rank,
        :name            => name,
        :sort            => upOrDown,
        :vsYesterday     => diff,
        :return          => ret,
        # :changerate      => ret,
        # :changeprice     => diff,

        :nowprice        => price
      )
      rankModel.save
    end
  end
end
