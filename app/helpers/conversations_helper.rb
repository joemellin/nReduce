module ConversationsHelper
  def time_for_conversation(time) 
    if time > Time.now.beginning_of_day
      return time.strftime("%-l:%M%P")
    else
      if time > Time.now.beginning_of_week
        return time.strftime("%a")
      else
        return time.strftime("%b %-d")
      end
    end
  end
end
