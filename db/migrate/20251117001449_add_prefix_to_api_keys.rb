class AddPrefixToApiKeys < ActiveRecord::Migration[8.1]
  def change
    add_column :api_keys, :prefix, :string
    add_index :api_keys, :prefix
  end
end
