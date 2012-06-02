class Startup < ActiveRecord::Base
  belongs_to :user
  belongs_to :batch
  belongs_to :location

  serialize :team_members
  attr_accessible :name, :team_members, :location_name, :product_url, :one_liner, :active

  validates_presence_of :name

  def team_members
    User.find(self['team_members'])
  end

    # Assign team members with an array of user ids
  def team_members=(user_ids = [])
    self['team_members'] = user_ids.uniq
  end
end
