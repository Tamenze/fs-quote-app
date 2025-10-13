class EnableNullifyOnUserDelete < ActiveRecord::Migration[8.0]
  def change
    change_column_null :tags, :created_by_id, true
    add_foreign_key :quotes, :users, column: :user_id,       on_delete: :nullify
    add_foreign_key :tags,   :users, column: :created_by_id, on_delete: :nullify
  end
end
