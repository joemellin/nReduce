class AddContextToRelationshipAndOnboardingOnUsers < ActiveRecord::Migration
  def change
    add_column :users, :onboarded, :integer, :length => 20
    add_column :relationships, :context, :integer, :length => 10
  end
end
