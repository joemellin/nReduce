class Screenr < Video

  def embed_code_html(width = 500, height = 315)
    "<iframe src='https://nreduce.viewscreencasts.com/embed/#{self.external_id}' width='#{width}' height='#{height}' frameborder='0'></iframe>"
  end

  def save_external_video_locally
    raise "Screenr: did not receive mp4 file url" if self.external_url.blank?
    # Save it locally
    self.save_file_locally(self.external_url, 'mp4')
  end
end