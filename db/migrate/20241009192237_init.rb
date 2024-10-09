class Init < ActiveRecord::Migration[7.1]
  def change
    create_table :groups
    create_table :users do |t|
      t.references :group
    end
    create_table :posts do |t|
      t.references :user
    end
  end
end
