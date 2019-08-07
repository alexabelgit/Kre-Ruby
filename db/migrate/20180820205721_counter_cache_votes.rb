class CounterCacheVotes < ActiveRecord::Migration[5.1]
  def change
    add_column :reviews, :votes_count, :integer, default: 0
    add_column :questions, :votes_count, :integer, default: 0
  end
end
