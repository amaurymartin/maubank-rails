class CreateAccessTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :access_tokens do |t|
      t.references :user, foreign_key: true, null: false

      t.text :token, null: false, index: { unique: true }
      t.datetime :revoked_at, precision: 6

      t.timestamps
    end
  end
end
