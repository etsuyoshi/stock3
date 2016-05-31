crumb :root do
  link "Home", root_path
end

# 全講座の紐付け
crumb :study do
  link "株式講座", '/study_pages/top'
  parent :root
end


# 初級編インデックス
crumb :study_elementary do
  link "初心者の為の株式取引の方法と仕組み", '/study_pages/elementary/top'
  parent :study
end

crumb :why_you_invest do
  link "なぜ投資をすべきか"
  parent :study_elementary
end

crumb :study_aboutstock do
  link "株とは"
  parent :study_elementary
end

crumb :study_stockmechanism do
  link "株の仕組み"
  parent :study_elementary
end

crumb :study_trademechanism do
  link "株取引の仕組み"
  parent :study_elementary
end

# 中級編
crumb :study_securities_fee do
  link "手数料"
  parent :study_elementary
end

crumb :study_securities_matsui do
  link "松井証券で口座を開く"
  parent :study_elementary
end

crumb :study_securities_sbi do
  link "SBI証券で口座を開く"
  parent :study_elementary
end

crumb :study_stock_merit do
  link "株式投資のメリット"
  parent :study_elementary
end
crumb :study_stock_demerit do
  link "株式投資のデメリット"
  parent :study_elementary
end

crumb :study_low_interest_rate_investment do
  link "マイナス金利時代の投資術"
  parent :study_elementary
end

crumb :study_market_detail do
  link "市場の詳細"
  parent :study_elementary
end

crumb :study_ipo do
  link "上場とは"
  parent :study_elementary
end

crumb :study_other_management do
  link "株以外の投資"
  parent :study_elementary
end

crumb :study_first_buy do
  link "最初に買う銘柄の選び方"
  parent :study_elementary
end

crumb :study_search_my_portfolio do
  link "自分に合う銘柄の探し方"
  parent :study_elementary
end
crumb :buy_matsui do
  link "初めて買ってみる"
  parent :study_elementary
end

crumb :sell_matsui do
  link "初めて売ってみる"
  parent :study_elementary
end

# 上級編
crumb :study_advanced do
  link "株価分析と売買手法"
  parent :study
end
crumb :current_employment_statistics do
  link "雇用統計と日本株"
  parent :study_advanced
end

crumb :analytics do
  link "株式分析"
  parent :study_advanced
end

crumb :apply_ipo do
  link "IPOに応募する"
  parent :study_advanced
end

crumb :determine_policy do
  link "運用方針を決める"
  parent :study_advanced
end

crumb :mini_kabu do
  link "ミニ株"
  parent :study_advanced
end

crumb :analyst do
  link "アナリスト"
  parent :study_advanced
end

crumb :analyst_report do
  link "アナリストレポート"
  parent :study_advanced
end

crumb :about_po do
  link "公募とは"
  parent :study_advanced
end
crumb :apply_po do
  link "公募に応募する"
  parent :study_advanced
end

crumb :bookbuilding do
  link "ブックビルディング"
  parent :study_advanced
end

crumb :ipo_challenge do
  link "IPOチャレンジ"
  parent :study_advanced
end

crumb :select_ipo do
  link "応募するIPO銘柄の選び方"
  parent :study_advanced
end

crumb :success_ipo do
  link "IPOで成功する"
  parent :study_advanced
end

crumb :methodology_find do
  link "銘柄を探す"
  parent :study_advanced
end

crumb :survey_popular do
  link "人気株を探す"
  parent :study_advanced
end

crumb :technical_chart do
  link "テクニカルチャート分析"
  parent :study_advanced
end

crumb :shareholder_incentive do
  link "お得な株主優待"
  parent :study_advanced
end

crumb :gyakuhibu do
  link "逆日歩"
  parent :study_advanced
end

crumb :credit_deal do
  link "信用取引"
  parent :study_advanced
end

crumb :mutual_fund do
  link "投資信託"
  parent :study_advanced
end

crumb :noload do
  link "ノーロード投信"
  parent :study_advanced
end

crumb :tax do
  link "税金"
  parent :study_advanced
end

crumb :devidend do
  link "配当"
  parent :study_advanced
end

crumb :nikkei225sakimono do
  link "日経225先物"
  parent :study_advanced
end

crumb :trade_techinique do
  link "売買テクニック"
  parent :study_advanced
end

crumb :foreign_investment do
  link "外国株投資"
  parent :study_advanced
end

crumb :foreign_currency_deposits do
  link "外貨普通預金口座"
  parent :study_advanced
end

crumb :try_mini_kabu do
  link "ミニ株を始めてみよう"
  parent :study_advanced
end


crumb :news do
  link "ニュース"
  parent :root
end


crumb :nikkei do
  link "日経平均"
  parent :root
end

crumb :fx do
  link "為替"
  parent :root
end

crumb :dow do
  link "ダウ平均"
  parent :root
end

crumb :shanghai do
  link "上海総合"
  parent :root
end
crumb :europe do
  link "欧州"
  parent :root
end
crumb :bitcoin do
  link "ビットコイン"
  parent :root
end
crumb :commodity do
  link "商品価格"
  parent :root
end
crumb :adr do
  link "日本株ADR"
  parent :root
end

crumb :kessan do
  link "決算"
  parent :root
end

crumb :login do
  link "ログイン"
  parent :root
end

# crumb :projects do
#   link "Projects", projects_path
# end

# crumb :project do |project|
#   link project.name, project_path(project)
#   parent :projects
# end

# crumb :project_issues do |project|
#   link "Issues", project_issues_path(project)
#   parent :project, project
# end

# crumb :issue do |issue|
#   link issue.title, issue_path(issue)
#   parent :project_issues, issue.project
# end

# If you want to split your breadcrumbs configuration over multiple files, you
# can create a folder named `config/breadcrumbs` and put your configuration
# files there. All *.rb files (e.g. `frontend.rb` or `products.rb`) in that
# folder are loaded and reloaded automatically when you change them, just like
# this file (`config/breadcrumbs.rb`).
