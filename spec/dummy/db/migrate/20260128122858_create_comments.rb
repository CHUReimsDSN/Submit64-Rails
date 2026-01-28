class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|

      t.belongs_to :article
      t.belongs_to :user

      t.timestamps
    end
  end
end
