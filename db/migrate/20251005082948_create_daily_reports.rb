class CreateDailyReports < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_reports do |t|
      t.date :date, null: false, index: { unique: true }
      t.text :content

      t.timestamps
    end
  end
end
