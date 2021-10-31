class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.uuid :key, null: false, index: { unique: true }
      t.text :full_name
      t.text :nickname, null: false
      t.text :username, index: { unique: true }
      t.text :email, null: false, index: { unique: true }
      t.text :password_digest, null: false
      t.text :documentation, index: { unique: true }
      t.date :date_of_birth

      t.datetime :confirmed_at, precision: 6
      t.timestamps
    end
  end
end
