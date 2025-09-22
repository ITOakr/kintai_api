class CreateWageHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :wage_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :wage, null: false
      t.date :effective_from, null: false

      t.timestamps
    end
  end
end
