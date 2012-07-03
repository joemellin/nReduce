class TagsController < ApplicationController
  before_filter :login_required

  def search
    if !params[:context].blank? and !params[:term].blank?
      tags = ActsAsTaggableOn::Tag.joins('INNER JOIN taggings ON tags.id = taggings.tag_id')
      tags = tags.where(['tags.name LIKE ? AND taggings.context = ?', "%#{params[:term]}%", params[:context]])
      tags = tags.order('tags.name').group('tags.id')
    else
      tags = []
    end
    respond_to do |format|
      format.json { render :json => tags.map{|t| t.name.titleize } }
    end
  end
end
