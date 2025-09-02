class BackfillUsersForTimeEntries < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      INSERT INTO users (id, name, email, created_at, updated_at)
      SELECT DISTINCT te.user_id,
             'Imported User ' || te.user_id,
             'imported+' || te.user_id || '@example.com',
             NOW(), NOW()
      FROM time_entries te
      LEFT JOIN users u ON u.id = te.user_id
      WHERE te.user_id IS NOT NULL
        AND u.id IS NULL;
    SQL
  end

  def down
    # データ移行は基本ロールバックしない（必要なら手動で）
  end
end
