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
    url = 'http://jp.reuters.com/news/archive/topNews?view=page&page=1&pageSize=100'

    html = open(url) do |f|
      f.read # htmlを読み込んで変数htmlに渡す
    end
    p "aaa"
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
          p "feed = " + feed_id.to_s + ", lastest = " + latest_id.to_s
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
          end
        end
      end
    end






    render :text => "Done!"
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


    # feed-idはstringとしてDBに登録されているが、実際には数字として比較して最新状態の確認を行っている
    # ->feed_idはDBの中のタイトルや記述から判定する必要がある？or feed_idを探索して最新ならincrement_idで最新性を付与する？
    # ->もしくはニュースの発行時間を取得してunixtimeに変換してfeed_idとする？


    # feed_idをunixtimeとして取得するために日時*YYYYMMDDhhmmssの記載がある画像URLを取得する
    # http://qiita.com/mogulla3/items/195ae5d8ad574dfc6baa
    image_url = content.xpath('div[@class="photo"]').css('a').css('img').attribute('src').value
    # p "image_url=" + image_url
    # http://s3.reutersmedia.net/resources/r/?m=02&d=20160212&t=2&i=1117106169&w=115&fh=&fw=&ll=&pl=&sq=&r=LYNXNPEC1B1A5
    # feed_id=image_url.sub(/)
    # yyyymmdd該当部分周辺の抜き出し
    tmp = image_url.match(/resources\/r\/\?m=02\&d=........\&t=2/)[0]
    yyyymmdd_article = tmp.sub(/resources\/r\/\?m=02\&d=/, "").sub(/\&t=2/,"")

    yyyy_article = yyyymmdd_article[0,4].to_i
    month_article = yyyymmdd_article[4,2].to_i
    dd_article = yyyymmdd_article[6,2].to_i

    # 時刻の取得：relatedInfoのjst-timepstampの中から取得する
    timestamp=content.xpath('div[@class="relatedInfo"]').xpath('span[@class="timestamp"]').inner_text
    hh_article=timestamp.match(/.*:/)[0].sub(/:/, "").to_i
    mm_article=timestamp.match(/:.*m/)[0].sub(/.m/, "").sub(/:/,"").to_i

    stringYMDHMS=yyyy_article.to_s + "-" + month_article.to_s + "-" + dd_article.to_s + " " + hh_article.to_s + ":" + mm_article.to_s + ":00"
    return unixtime = Time.parse(stringYMDHMS).to_i

  end
end
