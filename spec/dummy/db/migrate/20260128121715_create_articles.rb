class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :a_string
      t.text :a_text
      t.integer :a_number
      t.float :a_float
      
      t.belongs_to :user

      t.timestamps
    end
  end
end
