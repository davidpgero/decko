# -*- encoding : utf-8 -*-

class RemoveToolbarCards < Card::Migration::Core
  def up
    delete_code_card :activity_toolbar_button
    delete_code_card :rules_toolbar_button
  end
end
