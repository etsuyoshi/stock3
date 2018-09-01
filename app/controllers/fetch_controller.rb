class FetchController < ApplicationController
  # http://kazsix.hatenablog.com/entry/2014/04/20/222749
  require 'open-uri'# URLアクセス
  require 'kconv'    # 文字コード変換
  require 'nokogiri' # スクレイピング


  require 'time'
  require 'date'


  # require 'bundler/setup'
  require 'capybara/poltergeist'
  # Bundler.require

  def get_rank_from_nikkei
    _rank_controller = RankController.new
		_rank_controller.index
  end

  def gg(keyword)
    keyword = keyword.nil? ? "エストロゲン" : keyword
    p keyword
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, {:js_errors => false, :timeout => 5000 })
    end
    session = Capybara::Session.new(:poltergeist)
    session.driver.headers = {
        'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36"
    }
    session.visit 'http://www.related-keywords.com/'
    #search_input = session.find('#twotabsearchtextbox')#<input type="text" id="twotabsearchtextbox" value="" name="field-keywords" autocomplete="off" placeholder="" class="nav-input" dir="auto" tabindex="6">
    search_input = session.find("input[type='text']")#<input type="text" name="keyword" value="" style="width:258px;">
    search_input.native.send_key(keyword)

    #submit = session.find(:xpath, '//*[@id="nav-search"]/form/div[2]/div/input')#<input type="submit" value="取得開始">
    #submit = session.find("input[type='submit']")
    submit = session.find("input[value='取得開始']")
    submit.trigger('click')# 検索ボタンを押下
    # 検索結果を表示するまでスリープ
    sleep(1)

    # 検索結果が表示されたページをnokogiriでパース
    page = Nokogiri::HTML.parse(session.html)
    session.driver.quit
    outputs = []
    mecab = Natto::MeCab.new()
    page.css('li').each do |li|
      inner_text = li.inner_text
      if inner_text.include?(keyword)
        word = inner_text.gsub(/#{keyword}/,"").gsub(/ /,"").gsub(/　/,"").gsub(/\t/, "").to_s
        if word.nil? || word==""
          next
        end
        # 過去に存在しないもの
        if !outputs.include?(word)
          # 固有名詞判断
          mecabed = mecab.parse(word)
          mecab.parse(word) do |n|
            kkk = n.surface.to_s#単語
            parts = n.feature#品詞

            if parts.match(/(固有名詞|名詞,一般)/)#1文字以上の固有名詞と一般名詞のみ抽出
              outputs.push(kkk)
              p kkk + ":" + parts
            end
          end
        end
      end
    end
    p "----------------------------------------"

    # outputs.each do |output|
    #   p output
    # end
  end


  # phantomjsをheroku上で実行させる方法→https://pgmemo.tokyo/data/archives/1061.html
  def index
    get_news()#個別企業などのニュース
    get_bitcoin_news()
    get_kessan_news()#決算短信や本決算情報
    get_schedules()#国際統計情報
    return

    # render :text => "Done!"
    # 最新データの取得
    render 'price_newest/index'
  end

  def get_news()
    # ニュース(Feed.count)が300以上ある場合,300個以内になるように最初のものから順番に削除していく
    all_feed_count = Feed.count
    if all_feed_count > 300
      Feed.order(updated_at: :asc).first(all_feed_count - 300).each do |old_feed|
        old_feed.destroy
      end
    end

    noPage = 5
    while noPage >= 0 do
      # if TRUE#テスト用
      #   noPage = 0
      # end
      p "search(page=#{noPage}....)"
      url = "https://jp.reuters.com/news/archive/topNews?view=page&page=" + noPage.to_s + "&pageSize=10"
      doc = getDocFromHtml(url)
      latest_id = get_latest_reuter_id()

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
                description = description.gsub(/「信頼の原則」/,"").gsub(/信頼の原則/,"").gsub(/私たちの行動規範：/,"")

                #形態素解析して名刺のみkeywordカラム（なければ追加する必要あり）に格納する
                #http://watarisein.hatenablog.com/entry/2016/01/31/163327

                p feed_id
                p title
                p description
                p url
                p keyword


                #insert_feed(feed_id, title, description, url, keyword)#reuter_tagをつける
                # def insert_feed_with_all(feed_id, title, description, link, feedlabel, keyword, ticker)
                insert_feed_with_all(feed_id, title, description, url, "reuter", keyword, nil)
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

  # これからの予定(統計情報など)
  def get_schedules
    p "get schedules"
    # 今週予定
    # url = "http://www.koyo-sec.co.jp/market/event/" #https://www.jiji.com/jc/calendar"
    # url = "https://www.sbisec.co.jp/ETGate/?_ControlID=WPLETmgR001Control&_PageID=WPLETmgR001Mdtl20&_DataStoreID=DSWPLETmgR001Control&_ActionID=DefaultAID&burl=iris_morningInfo&cat1=market&cat2=morningInfo&dir=tl1-minfo%7Ctl2-stmkt%7Ctl3-stkview&file=index.html&getFlg=on"
    # url = "https://www.rakuten-sec.co.jp/web/market/calendar/"
    # url = "https://www.rakuten-sec.co.jp/smartphone/market/calendar/"
    # url = "https://info.finance.yahoo.co.jp/fx/marketcalendar/"
    url = "https://fx.minkabu.jp/indicators"

    # javascriptが動いているのでphantomjs(Capybaraによるpoltergeist)を使ってjs実行後のhtmlを取得する
    #poltergistの設定
    doc = getDocFromHtmlWithJS(url)
    page = doc.css('div.box')
    if page.css('h2').nil? || page.css('h2').count==0 || page.css('table.ei-list').nil?
      p "null"
      return
    else
      # どうせ古いやつから消されるし、ここではあえて消さなくてもいいかな(SEO的にも)
      # p "all delete"
      # Feed.tagged_with('market_schedule').each do |market_feed|
      #   market_feed.destroy
      # end
    end
    # 日付リストを取得する
    date_array = []
    page.css('h2').each do |each_date|
      p Time.at(Time.parse(each_date.inner_text).to_time.to_i)
      date_array.push(Time.parse(each_date.inner_text).to_time.to_i)#配列への追加
    end

    counter = 0
    page.css('table.ei-list').each do |list_day| #日付ごと

      date_unix_time = date_array[counter]
      counter = counter + 1
      list_day.css('tr.ei-list-item').each do |list_item|
        str_time = Time.at(date_unix_time).strftime('%Y-%m-%d').to_s + " " + list_item.css('td.time').inner_text + ":00"
        list_time = Time.parse(str_time)
        # p "時間 : " + list_item.to_s
        # <p class="flexbox__grow">ドイツ・卸売物価指数(前月比/前年比)</p>
        title = list_item.css('p.flexbox__grow').inner_text#本文
        if title.include?("・")
          # 最初のドットは国名を表しているのでtitle = "(" + title.gsub(/・/,")")としたいが、国名意外のドットも全部変換されてしまうためよくない
        end
        data = list_item.css('td.data')
        # 今回指標予想
        expects = data[1].inner_text
        # 前回指標予想
        before = data[0].inner_text
        # 影響度
        affects = list_item.css('td.hl').inner_text.gsub(/ /, "").gsub(/\t/,"").gsub(/\n/,"")
        description = "#{Time.at(list_time).strftime('%-m月%-d日')}に#{title}が発表されます。今回予想は#{expects}で前回は#{before}と発表された際、為替は#{affects}動きました。"

        # Feed.where(title: title).each do |same_feed|
        #   same_feed.destroy
        #   same_feed.save
        # end
        # seoの観点で既に存在していれば残す
        p "title = #{title}"
        # if Feed.where(title: title).count == 0
        #   feed = Feed.new(
        #     :feed_id          => list_time.to_time.to_i,
        #     :title            => title,
        #     :description      => description,
        #     :link             => "",
        #     :keyword          => "market_schedule"
        #   )
        #   feed.save
        #   p "saved: #{title} at #{feed.updated_at.in_time_zone('Tokyo')}"
        # else
        #   p "既に存在しているので保存しません"
        # end

        # def insert_feed_with_all(feed_id, title, description, link, feedlabel, keyword, ticker)
        insert_feed_with_all(list_time.to_time.to_i, title, description, "", nil, "market_schedule", nil)
      end
    end
  end

  #getKessan
  def get_kessan_news()
    # 決算眼形のニュース（過去）→過去のデータならこれでいい
    # url = "https://www.nikkei.com/markets/ir/compinfo/"
    # doc = getDocFromHtml(url)
    # doc.css('tbody').css('tr').each do |kessan_record|
    #   kessan_feed_id = Date.parse(kessan_record.css('th').inner_text.gsub(/\t/,"").gsub(/\n/,"")).to_time.to_i
    #   kessan_brand = kessan_record.css('td')[0].inner_text
    #   if !kessan_brand.nil?
    #     kessan_brand = kessan_brand.gsub(/ホールディングス/,"HD").gsub(/株式会社/,"").gsub(/グループ/,"")
    #   end
    #   kessan_title = kessan_record.css('td')[1].inner_text
    #   kessan_link = kessan_record.css('td')[1].css('a').attribute('href').value
    #   insert_feed_with_label(kessan_feed_id, kessan_title, nil, kessan_link, "kessan", kessan_brand)
    # end

    # 未来のニュースも含めて取得するなら以下のリンクから→そのうちやる？（その場合は取得側も現在以降を取得する必要がある）
    # https://www.nikkei.com/markets/kigyo/money-schedule/kessan/?ResultFlag=1&SearchDate1=2018%E5%B9%B408&SearchDate2=01
    # https://www.nikkei.com/markets/kigyo/money-schedule/kessan/?ResultFlag=1&kwd=&KessanMonth=&SearchDate1=2018%E5%B9%B408&SearchDate2=01&Gcode=%20&hm=2
    #常に7日前から7日後まで確認する
    start_time = Time.new - 7*24*3600
    #end_time = Time.new + 7*24*3600
    for i in 0..14
      p i.to_s + "日目"
      target_time = start_time + i * 24*3600
      searchDate1 = target_time.strftime('%Y') + "%E5%B9%B4" + target_time.strftime('%m')
      searchDate2 = target_time.strftime('%d')
      url_param = "ResultFlag=1&kwd=&KessanMonth=&SearchDate1=#{searchDate1}&SearchDate2=#{searchDate2}&Gcode=%20&hm="
      base_url = "https://www.nikkei.com/markets/kigyo/money-schedule/kessan/?" + url_param

      #loop_count = 1
      (1..10).each do |loop_count|
        url = base_url + loop_count.to_s
        # url = "https://www.nikkei.com/markets/kigyo/money-schedule/kessan/?ResultFlag=1&kwd=&KessanMonth=&SearchDate1=2018%E5%B9%B408&SearchDate2=01&Gcode=%20&hm=2"

        p "HTML取得中..url = #{url}"
    		doc = getDocFromHtmlWithJS(url)
        if doc.css('tbody').nil?
          break;
        elsif doc.css('tbody').css('tr.tr2').nil?
          break;
        elsif doc.css('tbody').css('tr.tr2')[0].nil?
          break;
        elsif doc.css('tbody').css('tr.tr2')[0].css('th').nil?
          break;

        #
        # hm=2以降も存在してしまうので終了条件を加える必要がある
        # 現在探索しているページに50商品ない場合は、そこで止める
        # 現在探索しているページに0商品しかない場合はそこで止める
        # 銘柄抽出が完了したタイミングで抽出銘柄数をカウントして50以上or0個なら続けないという仕組みで対応

        end

        num_kessans = 0
    		doc.css('tbody').css('tr.tr2').each do |kessan_record|
          if !kessan_record.nil? && !kessan_record.css('th').nil?
            tds = kessan_record.css('td')
            ticker = tds[0].inner_text.gsub(/\t/, "").gsub(/\n/,"")
            # 量が多いのでPriceseriesの中にある銘柄だけで実施する
            if Priceseries.where(ticker: ticker).count == 0
              p "#{ticker}=>225採用銘柄ではないのでスルー"
              next
            end
            kessan_feed_id = Date.parse(kessan_record.css('th').inner_text.to_s.gsub(/\t/, "").gsub(/\n/,"")).to_time.to_i
            name = tds[1].inner_text.gsub(/\t/, "").gsub(/\n/,"").gsub(/ホールディングス/,"HD").gsub(/株式会社/,"").gsub(/コーポレーション/,"").gsub(/自動車/,"自").gsub(/グループ/, "")
            timing = tds[3].inner_text.gsub(/\t/, "").gsub(/\n/,"")#決算期
            phase = tds[4].inner_text.gsub(/\t/, "").gsub(/\n/,"").gsub(/&nbsp/, "").gsub(/(\xc2\xa0)+/, '').gsub(/(\xc2\xa0|\s)+/, '')#第一、本
            company_type = tds[5].inner_text.gsub(/\t/, "").gsub(/\n/,"")#業種
            market_type = tds[6].inner_text.gsub(/\t/, "").gsub(/\n/,"")#上場場所
            kessan_title = name.to_s + "(#{market_type}一部:#{company_type}) " + (phase.to_s.include?("本") ? phase.to_s : (phase.to_s + "四半期")) + "決算"
            #kessan_title = name.to_s + "決算公表"
            kessan_description = name + "(#{market_type}一部:#{company_type},#{timing}本決算)は" +
              Time.at(kessan_feed_id.to_i).in_time_zone('Tokyo').strftime('%-m月%-d日') + "に" +
              (phase.to_s.include?("本") ? phase.to_s : (phase.to_s + "四半期")) + "決算を発表しました。"
            kessan_link = "https://www.nikkei.com/nkd/company/kigyo/?scode=" + ticker

            p "title = #{kessan_title}"
            p "desc = #{kessan_description}"
            #insert_feed_with_all(feed_id, title, description, link, feedlabel, keyword, ticker)
            insert_feed_with_all(kessan_feed_id, kessan_title, kessan_description, kessan_link, 'kessan', name, ticker)

            num_kessans = num_kessans + 1
          end
        end

        if num_kessans < 50 || num_kessans == 0
          break
        end
      end
    end

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
    insert_feed_with_all(feed_id, title, description, link, nil, keyword, nil)
  end

  def insert_feed_with_label(feed_id, title, description, link, feedlabel, keyword)
    insert_feed_with_all(feed_id, title, description, link, feedlabel, keyword, nil)
  end

  def insert_feed_with_all(feed_id, title, description, link, feedlabel, keyword, ticker)
    p "title:#{title}, desc:#{description}, feedlabel:#{feedlabel}, keyword:#{keyword}, ticker:#{ticker}"
    duplicated_feeds = Feed.where(title: title)
    # if duplicated_feeds.count > 0
    #   duplicated_feeds.all.each do |duplicates|
    #     duplicates.destroy
    #     duplicates.save
    #   end
    # end
    if duplicated_feeds.count == 0
      feed = Feed.new(
        :feed_id          => feed_id,
        :title            => title,
        :description      => description,
        :link             => link,
        :keyword          => keyword,
        :ticker           => ticker,
        :is_tweeted       => 0
      )
      p "created: feed(#{feed.id}:#{feed.title}, is_tweeted=#{feed.is_tweeted})"
      if !feedlabel.nil?
        feed.tag_list.add(feedlabel.split(','))
      end
      if !keyword.nil?
        feed.tag_list.add(keyword.split(','))
      end
      if feed.save
        if !Feed.where(title: title).first.nil?
          p "「#{Feed.where(title: title).first.title}」を保存しました"
        else
          p "#{title}→保存失敗"
        end
      else
        p "#{title}→保存失敗"
      end

    else
      p "既に存在するので保存しません"
    end
  end

  # DBに保存されている最新のfeed_id(unixtime)を取得
  def get_latest_reuter_id()
    row = Feed.tagged_with("reuter").order("feed_id desc").first
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

  # reuterの記事からfeedの時間を取得する(執筆時刻をfeed_idとする)
  def get_feed_id(content)

    # 当日記事かどうかを選ぶ
    isToday = false;
    article_id = content.css('a').attribute('href').value#/article/usa-fed-george-rates-idJPKBN13D215


    #記事本文のページを開いて時間(feed_id)と本文を取得する
    #記事リンク例
    #http://jp.reuters.com/article/usa-fed-bullard-idJPKBN13D1CF
    article_url = "https://jp.reuters.com#{article_id}"
    doc = getDocFromHtml(article_url)
    article_created = doc.xpath('//div[@class="ArticleHeader_date"]').inner_text
    p "article_created = #{article_created}"
    article_ymd = article_created.split("/")[0]
    article_hm = article_created.split("/")[1]
    #article_timestamp = Time.parse(article_ymd + " / " + article_hm)#<-こっちだと記事に記載されている時間をUTCとして登録してしまう
    article_timestamp = (article_ymd + " / " + article_hm).in_time_zone#記事に記載されている時間をJSTとして登録する
    p "article_ymd = #{article_timestamp}, #{article_timestamp.to_i}, #{Time.at(article_timestamp.to_i).in_time_zone('Tokyo')}"
    return_hash = Hash.new
    return_hash["feed_id"] = article_timestamp.to_i#Time.parse(stringYMDHMS).to_i
    article_content = doc.xpath('//div[@class="StandardArticleBody_body"]').inner_text
    return_hash["article"] = article_content

    return return_hash
  end



  # bitcoin関連のニュース
  def get_bitcoin_news
    # 最後のニュースのunixtimeを取得する
    # latest_id = get_latest_id()

    # 今までに格納したunixtimeを取得する
    arrReservedUnixTime =
    get_reserved_unix_time()

    # p "arrReservedUnixTime = #{arrReservedUnixTime}"


    # ビットコインニュース
    # url = "https://btcnews.jp/"
    url = "https://btcnews.jp/category/news/"
    # html = open(url) do |f|
    #   f.read # htmlを読み込んで変数htmlに渡す
    # end
    # doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')
    doc = getDocFromHtml(url)
    rank_all = Hash.new

    doc.search('li.article-list').each do |article|
      # p "title : " + article.css('h4').inner_text
      # p "url : " + article.css('a.link').attribute('href').value
      # p "date : " + Date.parse(article.css('div.meta').css('div.date').inner_text).to_s.gsub(/\n/,"").gsub(/\t/,"")
      # p "date.to_i = #{Date.parse(article.css('div.meta').css('div.date').inner_text).to_s.gsub(/\n/,"").gsub(/\t/,"").to_time.to_i}"
      article_title = article.css('h4').inner_text
      p "article_title = #{article_title}"
      article_url = article.css('a.link').attribute('href').value
      p "article_url = #{article_url}"
      article_doc = getDocFromHtml(article_url)
      if article_doc.nil?
        next
      elsif article.css('div.meta').nil?
        next
      elsif article.css('div.meta').css('div.date').nil?
        next
      elsif article.css('div.meta').css('div.date').inner_text.include?("Promotion")
        next
      end
      date_feed_id = Date.parse(article.css('div.meta').css('div.date').inner_text).to_s.gsub(/\n/,"").gsub(/\t/,"").to_time.to_i + 24*3599*Random.new.rand
      p "date_feed_id = #{Time.at(date_feed_id)}"
      # p "date_feed_id.to_time = #{Time.at(date_feed_id)}"
      # p "description : " + article_doc.search('div.article-details-body').inner_text.gsub(/\t/,"").gsub(/\n/, "")
      article_description = article_doc.search('div.article-details-body').inner_text.gsub(/\t/,"").gsub(/\n/, "")
      article_keywords = get_keywords_from_description(article_description)
      insert_feed_with_label(date_feed_id, article_title, article_description, article_url, "bitcoin", article_keywords)


      # p "article_description=#{article_description}"
      # p "article_url=#{article_url}"
      # p "article_keywords = #{article_keywords}"
    end
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
