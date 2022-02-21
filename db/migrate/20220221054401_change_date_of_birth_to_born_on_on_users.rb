class ChangeDateOfBirthToBornOnOnUsers < ActiveRecord::Migration[7.0]
  def change
    rename_column :users, :date_of_birth, :born_on
  end
end
