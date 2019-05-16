# -*- encoding : utf-8 -*-

class UpdatePristineData < Card::Migration::Core
  def up
    names = %w[
      home home+original
      *footer *credit *sidebar
      *title
      *all+*layout
      home+*self+*layout
      default_layout home_layout
      full_width_layout
      *header
      cardtype+*type+*structure
      ]
    names.select { |n| !Card.exists?(n) || Card.fetch(n)&.pristine? }
    merge_cards names
  end
end
