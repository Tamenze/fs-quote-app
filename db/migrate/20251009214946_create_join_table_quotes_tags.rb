class CreateJoinTableQuotesTags < ActiveRecord::Migration[8.0]
  def change
    create_join_table :quotes, :tags do |t|
      t.index [:quote_id, :tag_id], unique: true, name: "idx_quotes_tags_on_quote_and_tag"
      t.index [:tag_id, :quote_id], name: "idx_quotes_tags_on_tag_and_quote"
    end

    add_foreign_key :quotes_tags, :quotes, on_delete: :cascade
    add_foreign_key :quotes_tags, :tags, on_delete: :cascade
  end
end
