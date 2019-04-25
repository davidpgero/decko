include_set Abstract::CodeFile

def source_files
  %w[mod editor name_editor autosave doubleclick layout navbox upload filter slot modal overlay recaptcha
     slotter bridge
     nest_editor nest_editor_rules nest_editor_options nest_editor_name
     components decko follow card_menu slot_ready].map do |n|
    "decko/#{n}.js.coffee"
  end
end