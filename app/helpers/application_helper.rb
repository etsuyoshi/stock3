require 'natto'

module ApplicationHelper
  # seo-meta-tag
  # http://qiita.com/hirooooooo/items/f1a75cf0f2c581f0b620
  def default_meta_tags
  {
    # title:       "日本株チャートと初心者講座",
    # description: "日経平均に代表される日本株インデックスとダウジョーンズ指数に代表されるアメリカ株式市場やロンドン市場、ヨーロッパ市場、上海市場、商品価格などの海外市場における代表的な指数
    # のリアルタイムチャートで分析する投資総合ポータルと株式投資初心者講座",
    # keywords:    "投資,株,初心者講座,チャート,証券会社,日本,アメリカ,上海,ロンドン",
    # icon: image_url("favicon.ico"), # favicon
    noindex: ! Rails.env.production?, # production環境以外はnoindex
    charset: "UTF-8",
    name: 'viewport', content: 'width=device-width, initial-scale=1.0',
    # 上記name設定：http://yutori-engineer.hatenablog.com/entry/2016/01/09/103329
    # OGPの設定
    og: {
      title: "日本株チャートの初心者講座",
      type: "website",
      url: request.original_url,
      image: image_url("http://ichart.finance.yahoo.com/t?s=^N225"),
      site_name: "japanchart",
      description: "日本と世界の株式市場のリアルタイムチャートと初心者講座",
      locale: "ja_JP"
    }
  }
  end

# navbarのメニューアイテムの現在位置をアクティブにする
  def active_class(link_path)
    current_page?(link_path) ? "active" : ""
  end

  def get_foreign_hour(japanese_hour, hour_diff)
    if japanese_hour >= hour_diff
      foreign_hour = japanese_hour - hour_diff
    else
      foreign_hour = 24 + japanese_hour - hour_diff
    end
    return foreign_hour
  end
  # ロンドン時間の取得
  def get_London_hour(japanese_hour)
    hour_diff = 8
    return get_foreign_hour(japanese_hour.to_i, hour_diff)
  end

  def get_NewYork_hour(japanese_hour)
    hour_diff = 13
    return get_foreign_hour(japanese_hour.to_i, hour_diff)
  end

  #パラメータのデスクリプションから一般名詞及び固有名詞のみを抽出する（カンマ区切りで連結してreturn）
  def get_keywords_from_description(description)

    #めかぶ
    mecab = Natto::MeCab.new()
    # Natto::MeCab.new('-d /usr/local/lib/mecab/dic/mecab-ipadic-neologd')
    #サンプルテキスト
    #sample_text = "［フランクフルト　１８日　ロイター］ - 米セントルイス地区連銀のブラード総裁は、１２月の利上げ支持に傾きつつあるとし、実質的な問題は２０１７年の金利の道筋だとの見方を示した。同総裁はフランクフルトでのセミナーで「市場は現在、１２月の連邦公開市場委員会（ＦＯＭＣ）で措置を講じる可能性が高いと考えている。私もこれを支持する方向に傾いている」と述べた。ＦＯＭＣで投票権を有する同総裁は、米新政権の措置は２０１８年の経済に大きく影響する可能性があるが、移民制限や通商面での提案は大きく影響するのに１０年かかるかもしれないと指摘。「通商は協議が必要で何年もかかる。経済に大きく影響する可能性があるが、何年も、１０年もかかる問題だ」と述べた。新政権への移行に伴う政策変更の影響が実際に出てくるのは２０１８年から２０１９年にかけてとし、米連邦準備理事会（ＦＲＢ）の来年の見通しが変わることはないとの見方を示した。またＦＲＢの緩やかな利上げペースを正常化と呼ぶべきではないと指摘。２５ベーシスポイント（ｂｐ）程度の金利引き上げがマクロ経済に及ぼす影響は軽微で、ＦＲＢはやや上向きながらも事実上は据え置きのスタンスだとの見解を示した。移民については、どのような改革でも労働力の構成を変える可能性があるが、大きな影響は５－１０年で表れるとの見方を示した。規制や税制改革は１８－１９年に影響がでるとしたが、具体策が明らかになるまで判断は控えたいと語った。＊内容を追加して再送します"
    sample_text = description
    #予約語(これらのワードは抽出対象外とする)
    super_words = ["ロイター", "reuter", "世界", "内容", "あれ", "これ", "どれ", "それ"]

    keywords = ""
    mecab.parse(sample_text) do |n|

      word = n.surface.to_s#単語
      parts = n.feature#品詞

      # heroku側で日本語で機能することを確認済み
      if (parts.match(/(固有名詞|名詞,一般)/)) and (word.length>0)#1文字以上の固有名詞と一般名詞のみ抽出
        if !super_words.include?(word) and !keywords.include?(word)
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



  #Feedモデルの記事IDからkeywordを抽出し、同じキーワードが多く含まれている他の記事id配列を多い順番に作成する
  def similar_article(article_id)
    p "similar_article" + article_id.to_s
    feed = Feed.find(article_id)
    return_array = []

    if feed.keyword
      arr_keywords = feed.keyword.split(',')

      #p Feed.where("keyword like '%" + arr_keywords[0] + "%'").last.description
      #http://www.dna.affrc.go.jp/search/jp/
      #http://qiita.com/yutori_enginner/items/f0af67f62f4692d68370

      hist_article = Hash.new
      #上記の方法か、各キーワードで検索してヒットした記事集合の中で頻出する記事上位xxだけ抽出する
      arr_keywords.each_with_index do |keyword, i|
        obj_feeds = Feed.where("keyword like '%" + keyword + "%'")

        obj_feeds.each_with_index do |fd, j|
          if hist_article.has_key?(fd.id)
            hist_article[fd.id] += 1
          else
            hist_article[fd.id] = 1
          end
        end
      end

      #最新順:hash to array
      #arr_hist_article = hist_article.sort{|(k1, v1), (k2, v2)| k2 <=> k1 }
      #頻度順:hash to array
      arr_hist_article = hist_article.sort{|(k1, v1), (k2, v2)| v2 <=> v1 }
      arr_hist_article.each_with_index do |hist_art|
        # 自分以外の記事のみ格納する
        p "hist_art = #{hist_art[0]}"
        p "article_id = #{article_id}"
        if hist_art[0] != article_id
          return_array.push(hist_art[0])
        end
      end
    end #if keyword


    # 同じ業種の他の記事を探索
    # keyword、tagで業種、銘柄検索する
    # tagに業種、企業名、決算などを追加してrelated_tagsで検索する？
    related_tag_feeds = feed.find_related_tags
    related_tag_feeds.each do |related_feed|
      return_array.push(related_feed.id)

      p "related_feed = #{related_feed.id}, #{Feed.find(related_feed.id).first.}"
    end

    if feed.description
      hash_related_description = Hash.new(0)
      # description中における名詞の数だけループさせる
      get_keywords_from_description(feed.description).split(",").each do |included_keyword|
        # 最終的にはより多くの単語にマッチしているfeedのみを取得したい
        related_desc_feeds = Feed.where('description like ?', "%#{included_keyword}%")
        related_desc_feeds.each do |f|
          if hash_related_description.has_key?(f.id)
            hash_related_description[f.id] += 1
          else
            hash_related_description[f.id] = 1
          end
        end
      end
      hash_related_description.each do |hash_related_feed_id|
        p "hash_related_feed_id = #{hash_related_feed_id}"
        if hash_related_feed_id[1].to_i>=2#2回以上出現するfeedに限定する
          return_array.push(hash_related_feed_id[0])
        end
      end
    end



    return return_array.length > 0 ? return_array : nil#記事ID配列（多い順）


  end
end
