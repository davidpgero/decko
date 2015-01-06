include Card::FollowOption

follow_opts :position=>3, :special=>true

def title 
  'Following content you created'
end
  
def description set_card
  "#{set_card.follow_label} you edited"
end


def applies_to? card, user
  Card.search(:editor_of=>card.name).include? user
end
