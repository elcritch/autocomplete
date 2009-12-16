require ENV['TM_SUPPORT_PATH'] + '/lib/escape'
require ENV['TM_SUPPORT_PATH'] + '/lib/exit_codes'
require ENV['TM_SUPPORT_PATH'] + '/lib/osx/plist'
require ENV['TM_BUNDLE_SUPPORT'] + '/ctags_parser'

DIALOG = ENV['TM_SUPPORT_PATH']  + '/bin/tm_dialog' 

if ENV['DEBUG']=="TRUE"
  DEBUG = true 
else
  DEBUG = false
end

if ENV['TRACE']=="TRUE"
  require 'rubygems'
  require 'unroller'
  show=/cppcompletion.rb|ctags_parser.rb/
  # :exclude_classes => /CPPType|Ectag|EctagCollec/
  Unroller::trace :show_args => true, :display_style => :concise, :file_match => show
end

def snippet_generator(line)
  line.slice!(/\( (.+) \)/x)
  args = $1
  if args
    args = args.split(',')
    i = 0
    snips = args.collect{ |s| "${#{i+=1}:#{s}}" }
    line = "#{line}(#{snips.join(', ')})"
  end
  line
end


def execute
#   get the current line/word
  line, caret = ENV['TM_CURRENT_LINE'], ENV['TM_LINE_INDEX'].to_i
  line = line[0..caret-1]

  # Instantiate new TagParser and find mathcess..
  # we are using C++ module/object serperators...
  cppopts = { 
    :OBS => '\.', 
    :MOD => '::',
    :OBS! => ".", 
    :MOD! => "::",
    :TYPE => "CPP",
    :SYSTAGSDIR => ENV['TM_BUNDLE_SUPPORT'] + "/SystemTags/C++/",
    :WORD => '(?:(?:\w+::)*\*{0,2}\w+)',
  }

  # =====================
  # = Begin Tag Parser! =
  # =====================
  $errout = []
  tgp = TagParser.new(cppopts)
  candidates = tgp.doCandidates(line)
  partial = tgp.parsed[:partial]
  if partial.empty?
    # filter preceding '_' or other optional characters
    candidates = candidates.select{ |t| not t.name.match /^_/x }
  else
    # select names that begin with our partial selection
    candidates = candidates.select{ |t| t.name.match /^ #{partial} /x }
  end

  # =========================
  # = Format resulting tags =
  # =========================
  candidates = candidates.collect do |t|
    k = t['kind']
    k = t['signature'] if k.match(/function|prototype/)
    [t.name, k]
  end
  candidates = candidates.uniq.sort

  # TextMate.exit_show_tool_tip("No completion available for: #{tgp.parsed.inspect}") if candidates.empty? and !DEBUG
  raise "No completion available for: #{tgp.parsed.inspect}" if candidates.empty?

  fl = File.open("/tmp/output.txt","w")
  debug = true
  if debug
    $errout << "Candidates:"
    $errout << "candidates.length '#{candidates.length}'"
    $errout << "candidates: inspect:"
    $errout << candidates.collect { |k,v| "k: #{k} v: #{v}" }*"\n\t"
    $errout << "Done"
    fl.write($errout*"\n")
    # TextMate.exit_create_new_document($errout*"\n")
  end

  # out = ""
  # out << $errout*"\n"
  # fl = File.open("/tmp/output.txt", "w")
  # fl.write(out)
  
  if candidates.size > 1
    items = candidates.collect { |k,v| { 'title' => k+v } }
    plist = {'menuItems' => items}.to_plist
    # Run the tm_dialog command and load the result as a parsed property list.
    # NOTE: e_sh is provided by the escape module.
    res = OSX::PropertyList::load(`#{e_sh(DIALOG)} -up #{e_sh(plist)}`)
    TextMate.exit_show_tool_tip "No completion select" if res.empty?
    result = res['selectedMenuItem']['title']
  
  else candidates.size
    result = candidates.first.flatten.join(' ')
  end
  
  # simply display the returned path of the selected menu item
  result.slice!(/^#{tgp.parsed[:partial]}/)
  fl.write("\n\nResult: #{result}")
  result = snippet_generator(result)
  fl.write("\n\nResult: #{result}")

  print( result.inspect.tr('"','') )
end

begin 
  execute
rescue => exc
  case exc.message
  when "No etags found?", "Error in Parsing input line"
    TextMate.exit_show_tool_tip(exc.message)
  else
    begin
      out = ""
      out << htmlize($errout*"\n")
      out << htmlize("\n\nError! #{exc}\n" )
      out << exc.backtrace.inspect
      TextMate.exit_show_html out 
    rescue => rberr
      print "Error in Ruby Code"
      TextMate.exit_show_html( out + htmlize(rberr))
    end
  end
  
end




