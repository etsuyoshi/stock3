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
end
