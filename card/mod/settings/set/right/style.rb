require "sass"
include_set Abstract::Machine

store_machine_output filetype: "css"

format do
  def chunk_list  # turn off autodetection of uri's
    :nest_only
  end
end
