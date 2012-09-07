class Admin::MentorsController < ApplicationController
  before_filter :admin_required

  def index
    @mentors = User.with_roles(:nreduce_mentor).order('name')
  end

  def show
    @mentor = User.find_by_obfuscated_id(params[:id])
    @awesome_count_by_startup = Checkin.select('SUM(awesome_count) as total_awesomes, checkins.*').group('startup_id').inject({}){|res, c| res[c.startup_id] = c.total_awesomes.to_i; res }
    @currently_mentoring_ids = @mentor.pending_or_approved_relationships.map{|r| r.connected_with_id }
    @startups = Startup.onboarded.order('rating DESC').all.sort{|a,b| (@currently_mentoring_ids.include?(a.id) ? 0 : 1) <=> (@currently_mentoring_ids.include?(b.id) ? 0 : 1) }
  end

  # add connections - currently DOES NOT remove startups
  def update
    @mentor = User.find_by_obfuscated_id(params[:id])
    startups = Startup.find(params[:startup_ids])
    currently_mentoring_ids = @mentor.pending_or_approved_relationships.map{|r| r.connected_with_id }
    num_added = 0
    startups.each do |s|
      unless currently_mentoring_ids.include?(s.id)
        num_added += 1 if Relationship.start_between(@mentor, s, :startup_mentor)
      end
    end
    flash[:notice] = "#{num_added} new startups added for mentor."
    redirect_to admin_mentor_path(@mentor)
  end
end