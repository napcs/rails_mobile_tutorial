class CreateNewsItems < ActiveRecord::Migration
  def change
    create_table :news_items do |t|
      t.string :name
      t.text :body

      t.timestamps
    end
  end
end
