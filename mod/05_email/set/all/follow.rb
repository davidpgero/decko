card_accessor :followers


FOLLOWER_IDS_CACHE_KEY = 'FOLLOWER_IDS'

def label
  name
end

def follow_label
  name
end

def follow_option_card index
  if index and index < Card::FollowOption.names.size
    Card[Card::FollowOption.names[index]]
  end
end

def follow_option?
  codename && Card::FollowOption.names.include?(codename.to_sym) 
end


def followers
  follower_ids.map do |id|
    Card.fetch(id)
  end
end

def follower_names
  followers.map(&:name)
end

def follower_ids
  @follower_ids = read_follower_ids_cache || begin
    result = direct_follower_ids
    left_card = left
    while left_card and (follow_field_rule = left_card.rule_card(:follow_fields))

      follow_field_rule.item_names(:context=>left.cardname).each do |item|
        if item.to_name.key == key or 
           (item == Card[:includes].name and left.included_card_ids.include? id)
          result += left_card.direct_follower_ids
          break
        end
      end
      left_card = left_card.left
      
    end
    write_follower_ids_cache result
    result
  end
end


def direct_followers
  direct_follower_ids.map do |id|
    Card.fetch(id)
  end
end


# all ids of users that follow this card because of a follow rule that applies to this card
# doesn't include users that follow this card because they are following parent cards or other cards that include this card
def direct_follower_ids args={}  
  result = ::Set.new

  set_names.each do |set_name| 
    set_card = Card.fetch(set_name)
    set_card.all_user_ids_with_rule_for(:follow).each do |user_id|
      if (!result.include? user_id) and self.follow_rule_applies?(user_id)
        result << user_id
      end
    end
  end
  result
end



def all_direct_follower_ids_with_reason
  visited = ::Set.new
  set_names.each do |set_name| 
    set_card = Card.fetch(set_name)
    set_card.all_user_ids_with_rule_for(:follow).each do |user_id|
      if (!visited.include?(user_id)) && (follow_option_card = self.follow_rule_applies?(user_id))
        visited << user_id
        yield(user_id, :set_card=>set_card, :option_card=>follow_option_card)
      end
    end
  end
end


def follow_rule_applies? user_id
  rule_card(:follow, :user_id=>user_id).item_cards.each do |item_card|
    if item_card.respond_to?(:applies_to?) and item_card.applies_to? self, Card.fetch(user_id)
       return item_card
    end
  end 
  return false
end

def followed?; followed_by? Auth.current_id end

def followed_by? user_id
  follower_ids.include? user_id
end


# the set card to be followed if you want to follow changes of card
def follow_set_card
  if special_follow_option? name
    self
  else
    case type_code
    when :cardtype
      fetch(:trait=>:type)
    when :set
      self
    else
      fetch(:trait=>:self)
    end
  end
end

def follow_set
  follow_set_card.name
end

def follow_key
  follow_set_card.key
end

def related_follow_option_cards
  # refers to sets that users may follow from the current card
  @related_follow_option_cards ||= begin
    sets = set_names
    sets.pop unless codename == 'all' # get rid of *all set
    sets << "#{name}+*type" if known? && type_id==Card::CardtypeID
    sets << "#{name}+*right" if known? && cardname.simple?
    Card::FollowOption.names.each do |name|
      if Card[name].applies?(Auth.current, self)
        sets << name
      end
    end
    left_option = left
    while left_option
      sets << "#{left_option.name}+*self"
      left_option = left_option.left
    end
    sets.map { |name| Card.fetch name }
  end
end

def all_follow_option_cards
  sets = set_names
  sets += Card::FollowOption.names
  sets.map { |name| Card.fetch name }
end


event :cache_expired_because_of_new_set, :before=>:extend, :on=>:create, :when=>proc { |c| c.type_id == Card::SetID } do
  Card.follow_caches_expired
end

event :cache_expired_because_of_type_change, :before=>:extend, :changed=>:type_id do
  Card.follow_caches_expired
end

event :cache_expired_because_of_name_change, :before=>:extend, :changed=>:name do
  Card.follow_caches_expired
end

# event :follow_change, :before=>:extend, :when=> proc {|c| Env.params[:follow] || Env.params[:unfollow]} do
#   # if followed?
# #     if Env.params[:follow]
# #       if Auth.current.following_card.include_item? follow_set_card
# #         following_card = Auth.current.following_card
# #         following_card.drop_item follow_set
# #         following_card.save!
# #       end
# #     end
# #   else
# #     if Env.params[:unfollow]
# #         following_card = Auth.current.following_card
# #         following_card.add_item follow_set
# #         following_card.save!
# #       end
# #     end
# #   end
# end

format :html do
  watch_perms = lambda { |r| Auth.signed_in? && !r.card.new_card? }  # how was this used to be used?

  view :follow, :tags=>[:unknown_ok, :no_wrap_comments], :denial=>:blank, :perms=>:none do |args|
    wrap(args) do
      render_follow_link args
    end
  end
    
  def default_follow_set_card
    Card.fetch("#{card.name}+*self")
  end
  
  view :follow_link do |args|
    toggle = card.followed? ? :off : :on
    subformat(default_follow_set_card).render_follow_link args.reverse_merge(:toggle=>toggle)
  end
  

  view :follow_link_name do |args|
    args[:toggle] ||= card.followed? ? :off : :on
    if args[:toggle] == :off
      'following'
    else
      'follow'
    end
  end
  
  
  view :follow_menu, :tags=>:unknown_ok do |args|
    follow_links = [render_follow_link(args), advanced_follow_options_link]
    follow_links.compact.map do |link|
      { :raw => wrap(args) {link} }
    end 
  end
  
  def advanced_follow_options_link
    path_options = {:card=>card, :view=>:follow_options }
    html_options = {:class=>"slotter", :remote=>true}
    link_to "advanced...", path(path_options), html_options
  end
  

  # view :follow_menu_item do |args|
  #   index = args[:follow_menu_index] || (Env.params['follow_menu_index'] and Env.params['follow_menu_index'].to_i)
  #   if index and option_card = card.related_follow_option_cards[index] and option_card.followed?
  #     wrap(args) { follow_link(option_card) }
  #   else
  #     ''
  #   end
  # end
  
  view :follow_options do |args|
    if Auth.signed_in?
      args[:title] = "#{card.name}: follow options"
      #args[:optional_toggle] ||= main? ? :hide : :show
      frame_and_form( {
                          :action=>:update,
                          :id=>Auth.current.following_card.id,
                          :success=>{:id=>card.name, :view=>:open}
                      }, args, 'main-success'=>'REDIRECT' ) do
        [
          _render_follow_option_list( args ),
          _optional_render( :button_fieldset, args )
        ]
      end
    end
  end
  
  def default_follow_option_args args    
    args[:buttons] = %{
      #{ button_tag 'Submit', :class=>'submit-button', :disable_with=>'Submitting' }
      #{ button_tag 'Cancel', :class=>'cancel-button slotter', :href=>path, :type=>'button' }
    }
  end
  
  view :follow_option_list do |args|
    list = card.related_follow_option_cards.map do |option_card|
      subformat(option_card).render_checkbox(args.merge(:checked=>option_card.followed?, :label=>option_card.follow_label ))
    end.join("\n")
    %{
      <div class="card-editor editor">
      #{form.hidden_field( :content, :class=>'card-content')}
      <div class="pointer-checkbox-list">
        #{list}
      </div>
      </div>
    }
  end
  
  view :checkbox do |args|
    label = args[:label] || card.name
    checked = args[:checked]
    id = "pointer-checkbox-#{card.cardname.key}"
    %{ <div class="pointer-checkbox"> } +
      check_box_tag( "pointer_checkbox", card.cardname.url_key, checked, :id=>id, :class=>'pointer-checkbox-button') +
      %{ <label for="#{id}">#{label}</label>
      #{ %{<div class="checkbox-option-description">#{ args[:description] }</div>} if args[:description] }
       </div>}
  end


end

def write_follower_ids_cache user_ids
  hash = Card.follower_ids_cache
  hash[id] = user_ids
  Card.write_follower_ids_cache hash
end

def read_follower_ids_cache
  Card.follower_ids_cache[id]
end

module ClassMethods

  def follow_caches_expired
    Card.clear_follower_ids_cache
    Card.clear_user_rule_cache
  end


  def follower_ids_cache
    Card.cache.read(FOLLOWER_IDS_CACHE_KEY) || {}
  end
  
  def write_follower_ids_cache hash
    Card.cache.write FOLLOWER_IDS_CACHE_KEY, hash
  end

  def clear_follower_ids_cache
    Card.cache.write FOLLOWER_IDS_CACHE_KEY, nil
  end
#
#
#   def refresh_cached_sets
#     refresh_cache
#     refresh_ignore_cache
#   end
#
#   def refresh_cache
#     follow_cache = {}
#     Card.search( :left=>{:type_id=>Card::UserID}, :right=>{:codename=> "following"} ).each do |following_pointer|
#       following_pointer.item_cards.each do |followed|
#         key = followed.follow_key
#         if follow_cache[key]
#           follow_cache[key] << following_pointer.left_id
#         else
#           follow_cache[key] = ::Set.new [following_pointer.left_id]
#         end
#       end
#     end
#     Follow.store_cache follow_cache
#   end
#
#
#
end

