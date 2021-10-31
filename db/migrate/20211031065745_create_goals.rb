class CreateGoals < ActiveRecord::Migration[6.1]
  def change
    create_table :goals do |t|
      t.uuid :key, null: false, index: { unique: true }
      t.references :user, foreign_key: true, null: false

      t.text :description, null: false
      t.decimal :amount, null: false, precision: 11, scale: 2
      t.date :starts_at, null: false
      t.date :ends_at, null: false

      t.index [:user_id, :description], unique: true

      t.timestamps
    end
  end
end
