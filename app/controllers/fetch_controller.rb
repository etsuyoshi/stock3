class FetchController < ApplicationController
  # http://kazsix.hatenablog.com/entry/2014/04/20/222749
  require 'open-uri'# URLアクセス
  require 'kconv'    # 文字コード変換
  require 'nokogiri' # スクレイピング

  require 'time'
  require 'date'

  def index

    # スクレイピング先のURL
    # url = 'http://example.com/news/index.html'

    get_news

    # bitcoinの時系列データの取得
    get_btc

    get_event

    # render :text => "Done!"
    # 最新データの取得
    render 'price_newest/index'
  end

  private
  # feedsテーブルに1件INSERT
  def insert_feed(feed_id, title, description, link)
    feed = Feed.new(
      :feed_id          => feed_id,
      :title            => title,
      :description      => description,
      :link             => link
    )
    feed.save
  end

  # DBに保存されている最新のfeed_idを取得
  def get_latest_id()
    row = Feed.order("feed_id desc").first
    if row.nil?
      return 0
    end
    latest_id = row["feed_id"].to_i
    return latest_id
  end


  def get_feed_id(content)

    # feed_id => "/article/"を""に置換(スラッシュの前のバックスラッシュはエスケープシーケンス)
    # feed_id = url.sub(/\/article\//, "").to_s
    # p "feed_id = " + feed_id

    # 当日記事かどうかを選ぶ
    isToday = false;


    # 当日記事はxx:yy JST形式、前日以前は年月日時分JSTのような形式
    #まずはtimestampだけで記事発行時刻の取得を試る
    timestamp=content.xpath('div[@class="relatedInfo"]').xpath('span[@class="timestamp"]').inner_text
    #2016年 02月 13日 08:28 JSTのような形式であればこれを分解して時刻に変換する
    #↑のような日時形式でなければ(単なる時刻xx:yy JSTのような場合)は日にちは画像URLの中から取得する

    if timestamp.match(/.*年.*月.*日.*:.*ST/) != nil#前日以前であれば
      p timestamp.match(/.*年.*月.*日.*:.*ST/)[0]
      isToday = false
    else#当日記事の場合
      p timestamp.match(/.*ST/)[0]
      isToday = true
    end

    # feed_idをunixtimeとして取得するために日時*YYYYMMDDhhmmssの記載がある画像URLを取得する
    # http://qiita.com/mogulla3/items/195ae5d8ad574dfc6baa
    image_url = nil
    stringYMDHMS = nil
    p "isToday = #{isToday}"
    if isToday
      # 当日記事の場合は画像URLから発行時刻を図るしかない
      p content.xpath('div[@class="photo"]').length
      if content.xpath('div[@class="photo"]').length > 0
        image_url = content.xpath('div[@class="photo"]').css('a').css('img').attribute('src').value
        p "画像あり"
      else
        # 画像がない場合
        p "当日の記事で画像がない場合は仕方ないのでreturn値(unixtime=-1)として返して受け取る側で追加処理をしないこととする"
        return -1


      end

      p "image_url=" + image_url
      # http://s3.reutersmedia.net/resources/r/?m=02&d=20160212&t=2&i=1117106169&w=115&fh=&fw=&ll=&pl=&sq=&r=LYNXNPEC1B1A5
      # feed_id=image_url.sub(/)
      # yyyymmdd該当部分周辺の抜き出し
      tmp = image_url.match(/resources\/r\/\?m=02\&d=........\&t=2/)[0]
      p "tmp = " + tmp
      yyyymmdd_article = tmp.sub(/resources\/r\/\?m=02\&d=/, "").sub(/\&t=2/,"")
      p "yyyymmdd_art = " + yyyymmdd_article


      yyyy_article = yyyymmdd_article[0,4].to_i
      month_article = yyyymmdd_article[4,2].to_i
      dd_article = yyyymmdd_article[6,2].to_i

      # 時刻の取得：relatedInfoのjst-timepstampの中から取得する
      # timestamp=content.xpath('div[@class="relatedInfo"]').xpath('span[@class="timestamp"]').inner_text
      p "timestamp = " + timestamp
      hh_article=timestamp.match(/.*:/)[0].sub(/:/, "").to_i
      mm_article=timestamp.match(/:.*m/)[0].sub(/.m/, "").sub(/:/,"").to_i


      # am or pmで判別して、pmの場合でhh<13ならば12を追加する
      if hh_article < 12 && timestamp.match(/.pm/) != nil then #am-pm judge
        hh_article = hh_article + 12
      end

      stringYMDHMS=yyyy_article.to_s + "-" + month_article.to_s + "-" + dd_article.to_s + " " + hh_article.to_s + ":" + mm_article.to_s + ":00"
      p stringYMDHMS
      p "exit"
    else
      p timestamp
      # 前日以前の場合はtimestampに年月日時分が記載されているのでそこから抽出する
      timestamp = timestamp.match(/.*年.*月.*日.*:.*ST/)[0]
      p timestamp
      yyyy_article = timestamp[0,4].to_i
      p yyyy_article
      month_article = timestamp.match(/ .*月/)[0].sub(/ /, "").sub(/月/, "").to_i
      if month_article > 12
        month_article = month_article - 12
      end
      p month_article
      dd_article = timestamp.match(/月 .*日/)[0].sub(/ /, "").sub(/日/, "").sub(/月/, "").to_i
      if dd_article > 31
        dd_article = dd_article - 31
      end
      p dd_article
      hh_article = timestamp.match(/日 .*:/)[0].sub(/ /, "").sub(/:/, "").sub(/日/, "").to_i
      if hh_article > 24
        hh_article = hh_article - 24
      end
      p hh_article
      mm_article = timestamp.match(/:.* /)[0].sub(/ /, "").sub(/:/, "").to_i
      if mm_article > 60
        mm_article = mm_article - 60
      end

      p "y:" + yyyy_article.to_s
      p "month:" + month_article.to_s
      p "day:" + dd_article.to_s
      p "hour:" + hh_article.to_s
      p "minutes:" + mm_article.to_s

      stringYMDHMS=yyyy_article.to_s + "-" + month_article.to_s + "-" + dd_article.to_s + " " + hh_article.to_s + ":" + mm_article.to_s + ":00"
      p stringYMDHMS
    end
    p "param = #{stringYMDHMS}"
    p "params2 = #{Time.parse(stringYMDHMS)}"
    p "get_feed_id = #{Time.parse(stringYMDHMS).to_i}"

    return Time.parse(stringYMDHMS).to_i

  end

  def get_news
    noPage = 5

    while noPage > 0 do
      url = "http://jp.reuters.com/news/archive/topNews?view=page&page=" + noPage.to_s + "&pageSize=100"

      html = open(url) do |f|
        f.read # htmlを読み込んで変数htmlに渡す
      end

      # htmlをパース(解析)してオブジェクトを生成(utf-8に変換）
      doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')

      latest_id = get_latest_id()

      p "latest = " + latest_id.to_s

      doc.xpath('//div[@class="feature"]').each do |content|

        if !(content.nil?)
          # title
          title = content.css('h3').css('a').inner_text

          if !(title.nil? || title == "")
            feed_id = get_feed_id(content)
            if feed_id > 0 #コンテンツからunixtimeが取得できない記事の場合(unixtime=-1)は記事追加をしない
              p "feed : " + feed_id.to_s + "- lastest : " + latest_id.to_s + " = " + (feed_id.to_i - latest_id.to_i).to_s
              if latest_id < feed_id
                # DBに未登録の情報があったらDBに保存
                # title            = content.css('h1').to_html
                # description      = content.to_html
                # link             = url + '#news' + feed_id.to_s

                url = content.css('h3').css('a').attribute('href').value
                url = "http://jp.reuters.com" + url
                # http://jp.reuters.com/article/us-business-inventories-dec-idJPKCN0VL1XX


                # p Time.at(unixtime)


                # desc
                description = content.css('p').inner_text

                # p feed_id
                # p title
                # p description
                # p url

                insert_feed(feed_id, title, description, url)
                p "db挿入完了"
              else
                p "feed = " + feed_id.to_s + "がlastest=" + latest_id.to_s + "より小さいです。"
                p Time.at(feed_id)
              end
            end
          end
        end
      end
      noPage = noPage - 1
    end
  end

  def get_btc
    # 本当は取得時ではなく定期的に実行したい
    # http://www.coindesk.com/api/
    # http://qiita.com/awakia/items/bd8c1385115df27c15fa
    p "get_btc fetching.."
    duration = 500#test用に10にする→本番は100くらい取ってもいいかもしれない
    p "過去#{duration}日間のデータを取得しています"
    todayY_M_D = Time.now
    fromY_M_D = Time.now - 3600*24*duration

    endDate =  todayY_M_D.strftime('%Y-%m-%d')
    startDate =  fromY_M_D.strftime('%Y-%m-%d')
    strUrl = "https://api.coindesk.com/v1/bpi/historical/close.json?start=#{startDate}&end=#{endDate}"

    uri = URI.parse(strUrl)
    json = Net::HTTP.get(uri)
    result = JSON.parse(json)
    ymd = 0
    puts "取得した日付=#{result['bpi'].keys}"

    btc_index_ticker = "btci"
    btc_index_name="coindesk_btc_index"
    bpis = result['bpi']
    # p bpis
    # coindeskのindex
    bpis.keys.each do |key_date|#key=date
      # p key_date
      yyyy = key_date[0,4]
      mm = key_date[5,2]
      dd = key_date[8,2]

      close=bpis[key_date]


      ymd = "#{yyyy}#{mm}#{dd}"
      ymd = ymd.to_i

      # # 同一日付で当該ティッカー(btci)が存在しないかチェック
      # p ymd

      # btc_index_ticker = "^N225"
      # btc_index_ticker="btci"
      # ymd = 20160301
      newData = Priceseries.find_by(
      ticker: btc_index_ticker,
      ymd: ymd)

      if newData
        p "存在します"

        # 上書きする？
      else
        p "存在しません"

        priceOneDay = Priceseries.new(
          :ticker => btc_index_ticker, #string,
          :name => btc_index_name,#string,
          :open => close.to_f,#float,
          :high => close.to_f,#float,
          :low => close.to_f,#float,
          :close => close.to_f,#float,
          :volume => nil,#float,
          :ymd => ymd#integer
          )

        if priceOneDay.save
          p "#{ymd} #{close}　保存成功"
        else
          p "#{ymd} #{close}　保存失敗"
        end
      end
    end
  end


# eventを取得してイベントモデルに格納する
  def get_event
    p "get_event"
    # url = "http://nikkei225jp.com"
    url = "http://www.traders.co.jp/foreign_stocks/market_s.asp#today"

    html = open(url) do |f|
      f.read # htmlを読み込んで変数htmlに渡す
    end

    # htmlをパース(解析)してオブジェクトを生成(utf-8に変換）
    doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')

    strYm = nil
    doc.xpath('//table[@width="800px"]').children.each do |content|
      unless content.nil?
        if content.name == "tr"
          if content.inner_text.include?("年") &&
            content.inner_text.include?("月")

            strYm = content.inner_text
            strYm = strYm.gsub(/\t/, "")
            strYm = strYm.gsub(/\n/, "")
            strYm = strYm.gsub(/\r/, "")
            strYm = strYm.gsub(/\s/, "")

            if (strYm[0,4].to_i).is_a?(Integer)
              yyyy = strYm[0,4].to_i
              p "yyyy = #{yyyy}"
              mm = strYm.match(/年.*月/)[0].sub(/年/,"").sub(/月/,"").to_i
              p "mm = #{mm}"

              strYm = yyyy * 100 + mm
            else
              p "|#{strYm[0,4]}| is not integer"
            end

          end
        end
      end
    end

    doc.xpath('//table[@bordercolor="#AAB5BB"]').children.each do |content|
      unless content.nil?
        if content.name == "tr"
          date = content.children[1].inner_text
          # if date != " 日付"
          if !(date.include?("日付"))
            dd = date.match(/.*（/)[0].sub(/（/,"").to_i
            ymd = strYm.to_i * 100 + dd
            p "ymd = #{ymd}"

            # 海外のみ
            cell = content.children[3].to_s

            # cellからタグを削除
            cell = get_cell(cell)

            arrForeignContents = cell.split("<br>")
            # arrForeignContents.each do |foreign|
            #   p "#{date} : #{foreign}"
            # end
            arrForeignContents =
            get_append_event_array(arrForeignContents)

            cell = content.children[5].to_s
            # cellからタグを削除
            cell = get_cell(cell)

            arrDomesticContents = cell.split("<br>")
            # arrDomesticContents.each do |domestic|
            #   p "#{date} : #{domestic}"
            # end

            arrDomesticContents =
            get_append_event_array(arrDomesticContents)

            preserve_event(arrForeignContents, ymd)
            preserve_event(arrDomesticContents, ymd)
          end
        end
      end
    end
  end

  # 《》で囲まれている要素の次の要素を連結させる
  # 例：《》要素→新規上場、株式分割、決算発表など
  def get_append_event_array(arrEvent)
    p "get_append_event_array"
    str_tag = ""
    flg_append = false # 連結させるべき時のみ立てるフラグ
    arrReturn = []
    arrEvent.each do |event|
      if event.to_s[0] == "《"
        # p event.to_s
        flg_append = true
        str_tag = event.to_s
      else
        if flg_append
          strToPush = "#{str_tag}: #{event.to_s}"
          arrReturn.push(strToPush)
          flg_append = false
        else
          arrReturn.push(event.to_s)
        end
      end
    end

    arrReturn.each do |return_factor|
      p return_factor
    end
    return arrReturn
  end

  def get_cell(strCellParam)
    strCell = strCellParam.sub(/<td style=\"padding:5px;\" valign=\"top\"> <font size=\"2\">/, "")
    strCell = strCell.sub(/<\/font>\n<\/td>/, "")
    strCell = strCell.sub(/<b>/, "").sub(/<\/b>/, "")
    strCell = strCell.sub(/\"/,"")
    return strCell
  end

  def preserve_event(arrEvent, ymd)
    p "preserve_event : #{arrEvent[0]}, #{ymd}"
    # 引数で渡された配列の中のイベントを一つずつモデルに格納する
    # 注意：すでに存在するイベントについては保存しない
    arrEvent.each do |event|
      if event != '-' or event != "-"
        unless Event.find_by(ymd: ymd, name: event)
          Event.create(ymd: ymd, name: event)
          # p Event.last
        end
      end
    end
  end
end
