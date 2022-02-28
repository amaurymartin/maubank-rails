class AddBalanceToWallets < ActiveRecord::Migration[7.0]
  def change
    add_column :wallets, :balance, :decimal, null: false, precision: 11, scale: 2
  end
end
