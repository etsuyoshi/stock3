module ApplicationHelper
  # seo-meta-tag
  def default_meta_tags
  {
    title:       "日本株チャートの初心者講座",
    description: "日本株とアメリカ株式市場、上海の株式、商品価格を初心者講座で解説しながらリアルタイムチャートで分析",
    keywords:    "株,証券会社,日本,アメリカ,上海,ロンドン",
    # icon: image_url("favicon.ico"), # favicon
    noindex: ! Rails.env.production?, # production環境以外はnoindex
    charset: "UTF-8",
    # OGPの設定
    og: {
      title: "日本株チャートの初心者講座",
      type: "website",
      url: request.original_url,
      image: image_url("http://ichart.finance.yahoo.com/t?s=^N225"),
      site_name: "site name",
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
