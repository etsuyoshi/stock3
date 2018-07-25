class FetchController < ApplicationController
  # http://kazsix.hatenablog.com/entry/2014/04/20/222749
  require 'open-uri'# URLアクセス
  require 'kconv'    # 文字コード変換
  require 'nokogiri' # スクレイピング
  require 'natto'

  require 'time'
  require 'date'

  def get_rank_from_nikkei
    _rank_controller = RankController.new
		_rank_controller.index
  end



  def index
    get_news()
    # get_bitcoin_news()
    return


# Issue
# https://github.com/herval/yahoo-finance/issues/28

#以下デバッグ用に擬似コメントアウト
    #全体のデータ数が多い時に個別銘柄の中で多くの日数を抱えている銘柄を削除する
    remove_price_series#時系列データの削除

    #最新データを全て削除する
    remove_price_newest#最新データの削除


    #取得系

    get_bitcoin_news #bitcoin関連ニュースのノコギリ



    # スクレイピング先のURL
    # url = 'http://example.com/news/index.html'
    # ここらへんは全てfetch_controllerに寄せるべき
    #各インデックスをPriceseriesモデルに格納
    get_price_series("^DJI")


    get_price_series("^N225")
    get_price_series("000001.SS")
    get_price_series("^FTSE")



    # yahoo_client.historical_quotes("7203", { start_date: Time::now-3600*24*3, end_date: Time::now})
    # 以下、yahooのデータ提供停止に伴いコメントアウト
    # get_price_series("7203")#toyota
    # get_price_series("9437")#docomo
    # get_price_series("8306")#mufg
    # ここまではエラーなしで通過したことがある。
    # エラーの要因はActiveRecordを使わずに文字列で強制的に実行してしまっていることが問題である可能性

    #Priceseriesの7203の最新ymdから当日のランキングを作成するので個別銘柄Priceseries(db:nk225)を更新した後に実施する
    get_rank_from_nikkei

    get_price_newest#最新データの取得

    get_news#feedの更新

    # bitcoinの時系列データの取得
    #get_btc

    #coindeskに保存されている対USDのビットコイン価格を全て取得して最新の10件だけを格納する
    get_btc_csv

    get_event

    # render :text => "Done!"
    # 最新データの取得
    render 'price_newest/index'
  end

  private
  def remove_price_series
    p "時系列データ数= #{Priceseries.count}"
    #全PriceseriesDB件数が7000件を超過していたら各tickerのうち、500日数以上保有している銘柄の先頭10件を削除する
    #ただし、この方法だと499日ずつ保有している銘柄が14銘柄あってもどれも削除することができない
    if Priceseries.count > 7000#上限は確か1万件
      p "データ数が7000件を超えたので各インデックスで最初の何件か(現状10件にしているが実質どのくらいにすべきかわからない)を削除する"

      # まずはPriceseriesのインデックスをユニークに取得する
      array_indices = Priceseries.uniq.pluck(:ticker)
      array_indices.each do |ticker_index|
        p ticker_index

        # 当該インデックスが過去500日以上あれば削除
        count_data = Priceseries.where(ticker: ticker_index).count
        p "データ数=#{count_data}"
        if count_data > 500
          # ちょっと謙虚すぎるかもしれないが古いデータ10件だけ削除する
          p "データが多すぎるので削除します"
          Priceseries.where(ticker: ticker_index).order(ymd: :asc).limit(10).destroy_all
          p "削除後データ数=#{Priceseries.where(ticker: ticker_index).count}"
        end
      end
    else
      p "データ数は#{Priceseries.count}件なので削除しません"
    end
  end
  # 最新データが10000行以下になるように制御するため
  def remove_price_newest

    PriceNewest.delete_all

  end
  # feedsテーブルに1件INSERT
  def insert_feed(feed_id, title, description, link, keyword)
    feed = Feed.new(
      :feed_id          => feed_id,
      :title            => title,
      :description      => description,
      :link             => link,
      :keyword          => keyword
    )
    feed.save
    p "#{feed_id}保存成功"
  end

  def insert_feed_with_label(feed_id, title, description, link, feedlabel, keyword)
    feed = Feed.new(
      :feed_id          => feed_id,
      :title            => title,
      :description      => description,
      :link             => link,
      :keyword          => keyword
    )
    feed.tag_list.add(feedlabel)
    feed.save
  end

  # DBに保存されている最新のfeed_id(unixtime)を取得
  def get_latest_id()
    row = Feed.order("feed_id desc").first
    if row.nil?
      return 0
    end
    latest_id = row["feed_id"].to_i
    return latest_id
  end

  def get_reserved_unix_time()
    rows = Feed.pluck(:feed_id).last(100)
    if rows.nil?
      return nil
    else
      # return rows.to_i
      return rows
    end
  end


  def get_feed_id(content)
    p "get_feed_id"
    # feed_id => "/article/"を""に置換(スラッシュの前のバックスラッシュはエスケープシーケンス)
    # feed_id = url.sub(/\/article\//, "").to_s
    # p "feed_id = " + feed_id

    # 当日記事かどうかを選ぶ
    isToday = false;


    # <article class=\"story \">
    #   <div class=\"story-photo lazy-photo \">
    #     <a href=\"/article/usa-trump-putin-idJPKBN1392NA\">
    ########これでhttp://jp.reuters.com/article/usa-trump-putin-idJPKBN1392NA
    #       <img src=\"http://s2.reutersmedia.net/resources_v2/images/logo-placeholder-med.png\"
    #            org-src=\"http://s4.reutersmedia.net/resources/r/?m=02&amp;d=20161114&amp;t=2&amp;i=1161686232&amp;w=200&amp;fh=&amp;fw=&amp;ll=&amp;pl=&amp;sq=&amp;r=LYNXMPECAD1GR\"
    #            border=\"0\" alt=\"\">
    #     </a>
    #   </div>
    #   <div class=\"story-content\">
    #     <h3 class=\"story-title\">
    #       <a href=\"/article/usa-trump-putin-idJPKBN1392NA\">
    #         トランプ氏とプーチン大統領が電話会談、「協力関係」で一致
    #       </a>
    #     </h3>
    #     <div class=\"contributor\">
    #     </div>
    #     <p>［モスクワ　１４日　ロイター］ - ロシア政府は、プーチン大統領とトランプ次期米大統領が１４日に電話で会談し、「国際テロリズムや過激派との戦いなどにおいて建設的な協力関係」の構築を目指すことで合意したと明らかにした。
    #     </p>
    #     <time class=\"article-time\">
    #       <span class=\"timestamp\">8:11am JST</span>
    #     </time>
    #   </div>
    # </article>

    #doc.xpath('//article[@class="story "]').each do |content|


    #p "aaa = #{content.xpath('h3[@class="story-title"]').css('a').attribute('href').value}"
    article_id = content.css('a').attribute('href').value#/article/usa-fed-george-rates-idJPKBN13D215
    # article_id = "http://jp.reuters.com/#{content.xpath('a[@href]').value}"
    # p "article_id = #{article_id}"


    #記事本文のページを開いて時間(feed_id)と本文を取得する
    #記事リンク例
    #http://jp.reuters.com/article/usa-fed-bullard-idJPKBN13D1CF
    article_url = "https://jp.reuters.com#{article_id}"
    # html = open(article_url) do |f|
    #   f.read # htmlを読み込んで変数htmlに渡す
    # end
    # # htmlをパース(解析)してオブジェクトを生成(utf-8に変換）
    # doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')
    doc = getDocFromHtml(article_url)

    # <div class="group wrap" id="articleContent">
		#   <div class="article-header">
    #     <span class="article-section">Business</span>
    #     <span class="divider"> | </span>
    #     <span class="timestamp">2016年 11月 18日 23:29 JST</span>

    # article_timestamp = doc.xpath('//span[@class="timestamp"]').inner_text
    article_created = doc.xpath('//div[@class="ArticleHeader_date"]').inner_text
    p "article_created = #{article_created}"
    article_ymd = article_created.split("/")[0]
    article_hm = article_created.split("/")[1]

    article_timestamp = Time.parse(article_ymd + " / " + article_hm)
    p "article_ymd = #{article_timestamp}, #{article_timestamp.to_i}"
    return_hash = Hash.new
    return_hash["feed_id"] = article_timestamp.to_i#Time.parse(stringYMDHMS).to_i


    article_content = doc.xpath('//div[@class="StandardArticleBody_body"]').inner_text
    return_hash["article"] = article_content

    return return_hash



    #以下、昔のフォーマット:当日ニュースか前日以前のニュースかで条件分岐してリストのみから日付データを取得する方法

    p "#{content.xpath('div[@class="story-content"]').xpath('time[@class="article-time"]').xpath('span[@class="timestamp"]').inner_text}"
    # 当日記事はxx:yy JST形式、前日以前は年月日時分JSTのような形式
    #まずはtimestampだけで記事発行時刻の取得を試る
    timestamp=content.xpath('div[@class="story-content"]').xpath('time[@class="article-time"]').xpath('span[@class="timestamp"]').inner_text
    #2016年 02月 13日 08:28 JSTのような形式であればこれを分解して時刻に変換する
    #↑のような日時形式でなければ(単なる時刻xx:yy JSTのような場合)は日にちは画像URLの中から取得する
    p "timestamp=#{timestamp.to_s}"
    #p "match = #{timestamp.match(/.*年.*月.*日.*:.*ST/)}"
    p "match = #{timestamp.match(/.*年.*月.*日/)}"
    #if timestamp.match(/.*年.*月.*日.*:.*ST/) != nil#前日以前であれば
    if timestamp.match(/.*年.*月.*日/) != nil#前日以前
      p timestamp.match(/.*年.*月.*日/)[0]#時間帯JSTなどの記載がなくなったので別途取得する必要
      isToday = false
    else#当日記事の場合
      p timestamp.match(/.*ST/)[0]#時間帯によってはJSTなどの記号がない場合がある？=>遷移先に存在する
      #p timestamp.match(/.*年.*月.*日/)#年月日という表記
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
        p "画像あり:#{image_url}"
      else
        # 画像がない場合
        p "当日の記事で画像がない場合は仕方ないのでreturn値(unixtime=-1)として返して受け取る側で追加処理をしないこととする"
        #return -1
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
      #timestamp = timestamp.match(/.*年.*月.*日.*:.*ST/)[0]
      timestamp = timestamp.match(/.*年.*月.*日/)[0]
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

      return

      # 以下は取得できない
      # hh_article = timestamp.match(/日 .*:/)[0].sub(/ /, "").sub(/:/, "").sub(/日/, "").to_i
      # if hh_article > 24
      #   hh_article = hh_article - 24
      # end
      # p hh_article
      # mm_article = timestamp.match(/:.* /)[0].sub(/ /, "").sub(/:/, "").to_i
      # if mm_article > 60
      #   mm_article = mm_article - 60
      # end

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
    p "feed_id = #{Time.parse(stringYMDHMS).to_i}"

    return Time.parse(stringYMDHMS).to_i

  end

  # まだ作り途中
  def get_bitcoin_news
    # 最後のニュースのunixtimeを取得する
    # latest_id = get_latest_id()

    # 今までに格納したunixtimeを取得する
    arrReservedUnixTime =
    get_reserved_unix_time()

    # p "arrReservedUnixTime = #{arrReservedUnixTime}"


    # ビットコインニュース
    url = "https://btcnews.jp/"
    # html = open(url) do |f|
    #   f.read # htmlを読み込んで変数htmlに渡す
    # end
    # doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')
    doc = getDocFromHtml(url)
    rank_all = Hash.new
    # @bitcoinNews = []
    doc.xpath('//article').each do |article|
      # p "article:" + article.inner_html
      title = article.xpath('a').attribute('title').value
      url = article.xpath('a').attribute('href').value
      entry_date = article.xpath('div[@class="feat-meta"]/span[@class="feat_time entry-date"]').inner_html

      p "#{title}, #{entry_date}"
      published = nil
      article.xpath('div[@class="feat-meta"]/span[@class="feat_time entry-date"]').children.each do |child|
        p "pattern A"
        published = child.attribute("title").to_s
      end
      if published == nil || published.equal?("") then
        p "pattern B"
        article.xpath('div[@class="feat-right"]/div[@class="feat-meta"]/span[@class="feat_time entry-date"]').children.each do |child|
          published = child.attribute('title').to_s
        end
      end

      if published == nil || published.equal?("") then
        # 本当はpublishedなしでも適当に日付設定して保存したい
        p "publishedなし #{title}, #{url}, #{entry_date}"
      else
        p "published = #{published}"

        hash = Hash.new
        hash["title"] = title
        hash["url"] = url
        hash["entry_date"] = entry_date
        #transform
        # from "published"=>"2016-04-19T12:00:41+00:00"
        # to 2016-02-17 02:42:05(Feed.created_at form)
        years    =    published[0, 4].to_i
        months   =    published[5, 2].to_i
        dates    =    published[8, 2].to_i
        hours    =    published[11,2].to_i
        minutes  =    published[14,2].to_i
        seconds  =    published[17,2].to_i
        p "#{years}, #{months}, #{dates}, #{hours}, #{minutes}, #{seconds}"
        published_datetime =
        Time.local(years, months, dates,
                   hours, minutes, seconds)
        p "datetime = #{published_datetime.to_i} : #{title}"
        hash["published"] = published_datetime
        # @bitcoinNews[@bitcoinNews.count + 1] = hash
        # p "latest_id = #{latest_id}"
        p "published = #{published_datetime.to_i}"

        # if latest_id < published_datetime.to_i then
        # published_datetime.to_iを今までに格納したかどうか
        unless arrReservedUnixTime.include?(published_datetime.to_i.to_s) then
          # titleがDBに保存されていなければ、という条件に設定する
          insert_feed_with_label(published_datetime.to_i,
          title, nil, url, "bitcoin", nil)

          p "published = #{published_datetime.to_i}"
          p "title = #{title}"
          p "url = #{url}"

        end
      end
    end

    url = "https://news.bitcoin.com/"
    html = open(url) do |f|
      f.read # htmlを読み込んで変数htmlに渡す
    end
    doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')
    rank_all = Hash.new
    doc.xpath('//div[@class="td_module_12 td_module_wrap td-animation-stack"]').each do |article|
      # title
      title = article.xpath('div[@class="item-details"]/h3[@class="entry-title td-module-title"]/a').inner_text
      # time
      published = article.xpath('div[@class="item-details"]/div[@class="meta-info"]/div[@class="td-post-date"]/time').attribute("datetime").value
      # link
      url = article.xpath('div[@class="item-details"]/h3[@class="entry-title td-module-title"]/a').attribute("href").value
      hash = Hash.new
      hash["title"] = title
      hash["url"] = url
      #transform
      # from "published"=>"2016-04-19T12:00:41+00:00"
      # to 2016-02-17 02:42:05(Feed.created_at form)
      years    =    published[0, 4].to_i
      months   =    published[5, 2].to_i
      dates    =    published[8, 2].to_i
      hours    =    published[11,2].to_i
      minutes  =    published[14,2].to_i
      seconds  =    published[17,2].to_i
      published_datetime =
      Time.local(years, months, dates,
                 hours, minutes, seconds)
      hash["published"] = published_datetime
      # @bitcoinNews[@bitcoinNews.count + 1] = hash

      # if latest_id < published_datetime.to_i then
        # DBに保存されている最新ニュースより新しいニュースなので格納する
      unless arrReservedUnixTime.include?(published_datetime.to_i.to_s) then
        # titleがDBに保存されていなければ、という条件に設定する
        # insert_feed(published_datetime.to_i,
        # title, nil, url )
        insert_feed_with_label(published_datetime.to_i,
        title, nil, url, "bitcoin", nil)

        p "published = #{published_datetime.to_i}"
        p "title = #{title}"
        p "url = #{url}"

      end
    end
  end


  def get_news
    noPage = 5

    while noPage >= 0 do
      # if TRUE#テスト用
      #   noPage = 0
      # end
      p "search(page=#{noPage}....)"
      url = "https://jp.reuters.com/news/archive/topNews?view=page&page=" + noPage.to_s + "&pageSize=10"
      doc = getDocFromHtml(url)
      latest_id = get_latest_id()

      p "latest = " + latest_id.to_s

      #doc.xpath('//div[@class="story-content"]').each do |content|
      doc.xpath('//article[@class="story "]').each do |content|
        #content:
        # <article class=\"story \">
        #   <div class=\"story-photo lazy-photo \">
        #     <a href=\"/article/china-centralbank-easing-idJPKBN1KA05Y\">
        #       <img src=\"https://s1.reutersmedia.net/resources_v2/images/1x1.png\"
        #            org-src=\"https://s2.reutersmed&amp;sq=&amp;r=LYNXMPEE6J03H\"
        #            border=\"0\" alt=\"\">
        #     </a>
        #   </div>
        #   <div class=\"story-content\">
        #     <a href=\"/article/china-centralbank-easing-idJPKBN1KA05Y\">
        #       <h3 class=\"story-title\">\n\t\t\t\t\t\t\t\t焦点：中国人民銀が流動性増強、貿易戦争でさらなる金融緩和も</h3>\n\t\t\t\t\t\t\t</a>\n\t\t\t        <div class=\"contributor\"></div>\n\t\t\t        <p>中国人民銀行（中央銀行）が金融システムへの流動性供給を増やし、中小企業への信用供与を強化している。負債圧縮の取り組みによる借り入れコスト上昇で製造業生産や設備投資が鈍化し、元から景気の勢いが失われつつあったところに米国との貿易紛争が追い打ちを掛けたためだ。</p>\n\t\t\t\t\t<time class=\"article-time\">\n\t\t\t\t\t\t\t<span class=\"timestamp\">2018年 07月 21日</span>\n\t\t\t\t\t\t</time>\n\t\t\t\t\t</div>\n\t\t\t\t\n\t\t\t</article>
        if !(content.nil?)#contentに内容があれば
          # title
          title = content.css('h3').inner_text.gsub(/\n/,"").gsub(/\t/, "")
          p "title=#{title}"

          if !(title.nil? || title == "")
            feed_contents = get_feed_id(content)
            feed_id = feed_contents["feed_id"]

            p "feed_id = #{feed_id}"
            if feed_id > 0 #コンテンツからunixtimeが取得できない記事の場合(unixtime=-1)は記事追加をしない
              p "feed : " + feed_id.to_s + "- lastest : " + latest_id.to_s + " = " + (feed_id.to_i - latest_id.to_i).to_s
              if latest_id < feed_id
                # DBに未登録の情報があったらDBに保存
                # title            = content.css('h1').to_html
                # description      = content.to_html
                # link             = url + '#news' + feed_id.to_s

                url = content.css('a').attribute('href').value
                url = "http://jp.reuters.com" + url
                # http://jp.reuters.com/article/us-business-inventories-dec-idJPKCN0VL1XX

                # desc
                #description = content.css('p').inner_text
                description = feed_contents["article"]
                p "description = #{description}"
                keyword = get_keywords_from_description(description)
                description = description.sub(/。/,"。<br>")

                # 謎のワードが追加されるので削除する
                description = description.gsub(/信頼の原則/,"")

                #形態素解析して名刺のみkeywordカラム（なければ追加する必要あり）に格納する
                #http://watarisein.hatenablog.com/entry/2016/01/31/163327

                p feed_id
                p title
                p description
                p url
                p keyword


                insert_feed(feed_id, title, description, url, keyword)
                p "db挿入完了"
              else
                p "最新ニュースではない（feed = " + feed_id.to_s + "がlastest=" + latest_id.to_s + "より小さい）ので格納しません。"
                p Time.at(feed_id)
              end
            end
          end
        end
      end
      noPage = noPage - 1
    end
  end

  #パラメータのデスクリプションから一般名詞及び固有名詞のみを抽出する（カンマ区切りで連結してreturn）
  def get_keywords_from_description(description)

    #めかぶ
    mecab = #Natto::MeCab.new
    Natto::MeCab.new()
    # Natto::MeCab.new('-d /usr/local/lib/mecab/dic/mecab-ipadic-neologd')
    #サンプルテキスト
    #sample_text = "［フランクフルト　１８日　ロイター］ - 米セントルイス地区連銀のブラード総裁は、１２月の利上げ支持に傾きつつあるとし、実質的な問題は２０１７年の金利の道筋だとの見方を示した。同総裁はフランクフルトでのセミナーで「市場は現在、１２月の連邦公開市場委員会（ＦＯＭＣ）で措置を講じる可能性が高いと考えている。私もこれを支持する方向に傾いている」と述べた。ＦＯＭＣで投票権を有する同総裁は、米新政権の措置は２０１８年の経済に大きく影響する可能性があるが、移民制限や通商面での提案は大きく影響するのに１０年かかるかもしれないと指摘。「通商は協議が必要で何年もかかる。経済に大きく影響する可能性があるが、何年も、１０年もかかる問題だ」と述べた。新政権への移行に伴う政策変更の影響が実際に出てくるのは２０１８年から２０１９年にかけてとし、米連邦準備理事会（ＦＲＢ）の来年の見通しが変わることはないとの見方を示した。またＦＲＢの緩やかな利上げペースを正常化と呼ぶべきではないと指摘。２５ベーシスポイント（ｂｐ）程度の金利引き上げがマクロ経済に及ぼす影響は軽微で、ＦＲＢはやや上向きながらも事実上は据え置きのスタンスだとの見解を示した。移民については、どのような改革でも労働力の構成を変える可能性があるが、大きな影響は５－１０年で表れるとの見方を示した。規制や税制改革は１８－１９年に影響がでるとしたが、具体策が明らかになるまで判断は控えたいと語った。＊内容を追加して再送します"
    sample_text = description
    #予約語(これらのワードは抽出対象外とする)
    super_words = ["ロイター", "reuter", "世界", "内容", "あれ", "これ", "どれ", "それ"]

    keywords = ""
    mecab.parse(sample_text) do |n|

      word = n.surface.to_s
      parts = n.feature
      # firstpart = n.feature.split(',')[0].to_s#大分類
      # subpart = n.feature.split(',')[1].to_s#中分類

      if (parts.match(/(固有名詞|名詞,一般)/)) and (word.length>0)#1文字以上の固有名詞と一般名詞のみ抽出
        #puts "#{n.surface}\t#{n.feature} "
        if !super_words.include?(word)
          if keywords == ""
            keywords = word
          else
            keywords = keywords + "," + word
          end
        end
      end
    end
    return keywords

  end

  #ビットコイン価格取得:get_btcが機能しなくなった(301エラー)の為、csvで取得する方法に切り替える
  def get_btc_csv
    p "get btc csv..."
    csv_url = "https://api.bitcoinaverage.com/history/USD/per_day_all_time_history.csv"

    agent = Mechanize.new
    #csv = agent.get_file("http://k-db.com/stocks/#{date}?download=csv")
  	csv = agent.get_file(csv_url)
  	#p "getCSV:#{!csv}"
  	if !csv || csv==""
  		return nil
  	end

    csv = NKF.nkf('-wxm0', csv) #utf8に変換
    csv = csv.split("\r\n")
    keys = csv[0].split(",")
  	p "keys = #{keys.to_s}"

    rows = []
    p "csv取得完了→変数変換開始"
    csv.each_with_index do |v1,i1|#v1が一行の文字列、i1が行番号
      next if i1 < 1
      #break if i1 == 10
      row = {}

      v1.split(",").each_with_index do |v2,i2|#v2が各要素、i2が列番号
        row[keys[i2]] = v2
        #p "col=#{i2}, key=#{keys[i2]}, cell=#{v2}"
      end
      rows << row
    end

    if rows.length == 0
      return
    end

    #p "a = " + rows[1]["High"]

    p "変数変換完了→DB格納開始"
    #上（最新値）の行から順番に実行するので欲しいデータ数(日数)だけ取得

    rows.each_with_index do |each_row, row_num|
      break if row_num == 10 #10行まで取得する
      row_date = each_row["DateTime"]
      row_high = each_row["High"]
      row_low  = each_row["Low"]
      row_close= each_row["Average"]
      row_volume = each_row["Volume BTC"]

      if row_high == ""
        row_high = each_row["Average"]
        row_low  = each_row["Average"]
      end
      #p "row:#{each_row}"
      p "date:#{row_date}, high:#{row_high}, low:#{row_low}, volume=#{row_volume}"
      ymd = Date.strptime(row_date,'%Y-%m-%d 00:00:00')#文字列を一度日付オブジェクトに変換
      ymd = ymd.strftime("%Y%m%d")#日付オブジェクトからYYYYMMDDに変換
      btc_index_ticker = "btci"#tickerに変換
      btc_index_name="coindesk_btc_index"#nameオブジェクトに変換

      ps = Priceseries.where(ticker: btc_index_ticker).where(ymd: ymd).first
      p "ps = #{ps}"
      if ps
        p "既にDBに存在するので何もしません"
      else
        p "まだDBにないので格納します"
        priceOneDay = Priceseries.new(
          :ticker => btc_index_ticker, #string,
          :name => btc_index_name,#string,
          :open => row_close.to_f,#float,
          :high => row_high.to_f,#float,
          :low => row_low.to_f,#float,
          :close => row_close.to_f,#float,
          :volume => row_volume.to_f,#float,
          :ymd => ymd#integer
          )

        if priceOneDay.save
          p "#{ymd} #{row_close}　保存成功"
        else
          p "#{ymd} #{row_close}　保存失敗"
        end
      end
    end


  end
  #coindeskからビットコイン価格の取得=>なぜか取得できない...
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
             #https://api.coindesk.com/v1/bpi/historical/close.json?start=2015-06-25&end=2016-11-06
    p "strUrl:#{strUrl}"
    uri = URI.parse(strUrl)
    p "uri:#{uri}"
    p "host:#{uri.host}"
    p "port:#{uri.port}"

    # https = Net::HTTP.new(uri.host, uri.port)
    # https.use_ssl = true
    # res = https.start {
    #   https.get(uri.request_uri)
    # }
    #
    # if res.code == '200'
    #   result = JSON.parse(res.body)
    #   # Railsだったらこう書ける`require 'json'`なしで
    #   # result = ActiveSupport::JSON.decode res.body
    #
    #   # resultを使ってなんやかんや処理をする
    #   p result
    # else
    #   puts "OMG!! #{res.code} #{res.message}"
    # end
    # return

    json = Net::HTTP.get(uri)

    p "json:#{json}"#ここでjsonが空文字になっているので以下エラーとなる
    return
    #以下、デバッグ
    # https://bbvaopen4u.com/en/actualidad/coindesk-bitpay-and-coinbase-apis-developing-bitcoin-apps
    # https://github.com/enriquez/coinpocketapp.com
    # https://github.com/dan-silver/coinbase_exchange
    result = JSON.parse(json)
    p "result:#{result}"
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


  def get_price_series(ticker)
    # 既に格納されている最新データを取得
    name = nil
    if ticker == "^N225"
      name = "nikkei225"
    elsif ticker == "^DJI"
      name = "dow"
    elsif ticker == "000001.SS"
      name = "shanghai"
    elsif ticker == '^FTSE'
      name = "FTSE"
    elsif ticker.to_s.downcase == '7203'
      name = "TOYOTA(7203.T)"
    else
      name = "notSet"
    end


    todayObj = Time::now #ex. 2016-02-21 12:22:21 +0900
    # newestYMD = Priceseries.maximum("ymd") #ex.20160122
    newestYMD = "20130101"#データがない場合に備えデフォルトを設定
    if Priceseries.find_by(ticker: ticker)
      # 最後の日付を取得->find_by_sqlだとpostgresqlで無効になる可能性があるため→なるべくActiveRecord !!!!
      # newestYMD = Priceseries.find_by_sql('select * from priceseries where ticker = "' + ticker + '" order by ymd desc limit 1')[0]["ymd"]
      # newestYMD = Priceseries.find_by_sql("select * from priceseries where ticker = '" + ticker + "' order by ymd desc limit 1 ")[0]["ymd"]
      newestYMD = Priceseries.where(ticker: ticker).order(ymd: :asc).limit(1)[0].ymd

      # p "sql result = #{Priceseries.find_by_sql("select * from priceseries where ticker = '" + ticker + "' order by ymd desc limit 1 ")[0]["ymd"]}"
      # p "ActiveRecord = #{newestYMD}"
    end

    newestYear = newestYMD.to_s[0,4].to_i
    newestMonth = newestYMD.to_s[4,2].to_i
    newestDay = newestYMD.to_s[6,2].to_i

    if newestYear == todayObj.year &&
      newestMonth == todayObj.month &&
      newestDay   == todayObj.day
      p "本日まで取得済み"
    else
      p newestYMD.to_s + "から本日まで株価取得"
      # DBに保存されている最新データの日付
      newestObj = Time.zone.local(newestYear, newestMonth, newestDay)
      p newestObj
      p Time::now

      insert_PriceSeries(ticker, name, newestObj)

    end
  end


  def insert_PriceSeries(ticker, name, fromYmdObj)
    p "insert_PriceSeries"
    yahoo_client = YahooFinance::Client.new
    #p "yahoo:#{yahoo_client}"
    # data = yahoo_client.quotes(["BVSP", "NATU3.SA", "USDJPY=X"], [:ask, :bid, :last_trade_date])
    # data = yahoo_client.historical_quotes("^DJI", { raw: false, period: :monthly })
    # datas = yahoo_client.historical_quotes("^N225", { start_date: Time::now-(24*60*60*4), end_date: Time::now }) # 10 days worth of data
    datas = yahoo_client.historical_quotes(ticker, { start_date: fromYmdObj, end_date: Time::now})

    # dows = yahoo_client.historical_quotes("^DJI", { start_date: Time::now-(24*60*60*200), end_date: Time::now }) # 10 days worth of data
    # p dows

    # p datas

    # 取得したデータ
    # <OpenStruct
    #  trade_date="2016-02-19",
    #  open="16050.400391",
    #  high="16050.459961",
    #  low="15799.349609",
    #  close="15967.169922",
    #  volume="156800",
    #  adjusted_close="15967.169922",
    #  symbol="^N225">

    # Priceseriesに格納する
    # Priceseries(id: integer,
    #   ticker: string,
    #   name: string,
    #   open: float,
    #   high: float,
    #   low: float,
    #   close: float,
    #   volume: float,
    #   ymd: integer,
    #   created_at: datetime,
    #   updated_at: datetime)

    datas.each do |data|
      # from "2016-02-19"-format to "20160219"
      datasDate = data.trade_date
      y = datasDate[0,4].to_s
      m = datasDate[5,2].to_s
      d = datasDate[8,2].to_s

      insertDate = y + m + d
      p "Date:#{insertDate}, ticker:#{ticker}, close:#{data.close}"



      priceOneDay = Priceseries.new(
        :ticker => ticker, #string,
        :name => name,#string,
        :open => data.open,#float,
        :high => data.high,#float,
        :low => data.low,#float,
        :close => data.close,#float,
        :volume => data.volume,#float,
        :ymd => insertDate#integer
        )


      priceOneDay.save



    end
  end


  def get_price_newest

    # ticker = ["USDJPY=X", "EURJPY=X"];
    # nikkei, dji=>取得不能, 上海総合、CSI300, 上海B株、深センB株、上海Ａ株, 深センＡ株, HangSeng, 香港H株指数,S&P,ロシア,ブラジル
    ticker = ["^N225", "^DJI", "000001.SS", "000300.SS", "000003.SS", "399108.SZ",
      "000002.SS", "399107.SZ", "^HIS", "^HSCE", "^HSCC", "^KS11", "^TWII", "^GSPC", "^FTSE", "^HSI",
       "RTS.RS", "^BVSP","^GSPTSE", "^AORD", "^JKSE", "EZA",
       "^NZ50", "^AXJO", "^STI", "^GDAXI", "FTSEMIB.MI", "^MERV", "^MXX",
       "^KLSE", "^SSMI",
       "7203"];
    currencies = ["JPY", "USD", "EUR", "AUD", "CNY", "CHF", "CAD", "HKD", "ITL"];
    # usd jpy eur cny gbp gem chf cad aud itl
    currencies.each do |cur1|
      currencies.each do |cur2|
        if cur1 != cur2
          ticker.push(String(cur1+cur2+"=X"))
        end
      end
    end
    # 地図に使うソブリンストックインデックス
    # n225, hsce(hansen)?^hsi, ks11(kankoku), twii(taiwan),^ftse(england), ^GSPC(S&P), dax(german)

    # 今は最初のコードしか取得できていない


    # 将来的に別メソッドにする
    # get_yahoo_data(ticker)

    # yahooからtickerコードの最新情報を取得する
    yahoo_client = YahooFinance::Client.new
    yahoodata =
      yahoo_client.quotes(
        [ticker],#続けて取得する場合はカンマ区切りで配列にして渡すex. ["USDJPY=X, EURJPY=X"],
        [:last_trade_price, :ask, :bid, :last_trade_date, :previous_close])
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
        previous_price = ydata.previous_close.to_d
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
           ask_usdjpy, bid_usdjpy,
           previous_price)

      end
      i = i + 1
    end
  end

  # パラメータdateはYYYYMMDDとする
  def insert_price_data(ticker, price, date, ask, bid, previous)
    # PriceNewest(id: integer, ticker: string, pricetrade: float, datetrade: integer, ask: float, bid: float, created_at: datetime, updated_at: datetime)
    # [#<OpenStruct last_trade_price=\"113.9850\", ask=\"114.0000\", bid=\"113.9850\", last_trade_date=\"2/27/2016\", previous_trade_date=nil, previous_trade_price=nil>

    # すでにそのティッカーコードで同じ日付があれば取得しないようにする
    if !(PriceNewest.find_by(ticker: ticker, datetrade: date))
      pricedata = PriceNewest.new(
        :ticker           => ticker,
        :pricetrade       => price,
        :datetrade        => date,#ymd
        :ask              => ask,
        :bid              => bid,
        :previoustrade    => previous
      )
      p "insert below.."
      p "ticker = #{pricedata.ticker}"
      p "pricetrade = #{pricedata.pricetrade}"
      p "datetrade = #{pricedata.datetrade}"
      p "ask = #{pricedata.ask}"
      p "bid = #{pricedata.bid}"
      p "previous=#{pricedata.previoustrade}"
      pricedata.save
    else
      p "そのデータはすでに存在します=>#{PriceNewest.find_by(ticker: ticker, datetrade: date)}"
    end


  end
end
