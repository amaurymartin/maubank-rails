class CreateCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :categories do |t|
      t.uuid :key, null: false, index: { unique: true }
      t.references :user, foreign_key: true, null: false

      t.text :description, null: false

      t.index [:user_id, :description], unique: true

      t.timestamps
    end
  end
end
