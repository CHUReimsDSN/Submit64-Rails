class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :fullname

      t.timestamps
    end
  end
end
