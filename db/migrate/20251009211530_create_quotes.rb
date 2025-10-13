class CreateQuotes < ActiveRecord::Migration[8.0]
  def change
    create_table :quotes do |t|
      t.text :body, null: false 
      t.string :attribution, null: false 
      t.bigint :user_id
      t.timestamps
    end

    add_index :quotes, :user_id
    add_index :quotes, :created_at 
  end
end
