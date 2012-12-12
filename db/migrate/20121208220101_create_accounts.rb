class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :owner_id
      t.string :owner_type
      t.integer :balance, :escrow, :default => 0
      t.timestamps
    end

    add_index :accounts, [:owner_id, :owner_type], :unique => true

    # Create accounts for everyone
    Account.transaction do
      Startup.all.each{|s| Account.create_for_owner(s) }
    end

    # Update twitter follower count for all users with startups
    User.transaction do
      Authentication.group(:user_id).includes(:user).where(:provider => 'twitter').each{|a| a.user.update_twitter_followers_count if a.user.startup_id.present? }
    end
  end
end
