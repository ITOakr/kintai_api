class ChangeFoodCostsForCategorization < ActiveRecord::Migration[8.0]
  def change
    drop_table :food_costs

    # 新しい構造でfood_costsテーブルを作成
    create_table :food_costs do |t|
      t.date :date, null: false
      # カテゴリを整数型で保存するように変更 (enumのため)
      t.integer :category, null: false
      t.integer :amount_yen, null: false, default: 0
      t.string :note

      t.timestamps
    end

    # 日付でデータを検索しやすくするためにインデックスを追加
    add_index :food_costs, :date
  end
end
