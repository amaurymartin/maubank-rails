class CreateBudgets < ActiveRecord::Migration[6.1]
  def change
    create_table :budgets do |t|
      t.uuid :key, null: false, index: { unique: true }
      t.references :category, foreign_key: true, null: false

      t.decimal :amount, null: false, precision: 11, scale: 2
      t.date :starts_at, null: false
      t.date :ends_at

      t.index [:category_id, :starts_at], unique: true
      t.index [:category_id, :ends_at], unique: true

      t.timestamps
    end
  end
end
