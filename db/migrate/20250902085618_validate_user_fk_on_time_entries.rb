class ValidateUserFkOnTimeEntries < ActiveRecord::Migration[8.0]
  def up
    execute "ALTER TABLE time_entries VALIDATE CONSTRAINT fk_rails_b471d1824b;"
  end
  def down
    # no-op（validate を戻すことは通常しない）
  end
end
