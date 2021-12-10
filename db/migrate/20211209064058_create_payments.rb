class CreatePayments < ActiveRecord::Migration[6.1]
  def change
    create_table :payments do |t|
      t.uuid :key, null: false, index: { unique: true }
      t.references :category, foreign_key: true
      t.references :wallet, foreign_key: true, null: false

      t.date :effective_date, null: false
      t.decimal :amount, null: false, precision: 11, scale: 2

      t.index :effective_date

      t.timestamps
    end
  end
end
