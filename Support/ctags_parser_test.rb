require 'test/unit'

if __FILE__ == $0  
  ENV['TM_BUNDLE_PATH']   ="/Users/jaremy/Library/Application Support/TextMate/Bundles/AutoCompletion.tmbundle"
  ENV['TM_BUNDLE_SUPPORT']="/Users/jaremy/Library/Application Support/TextMate/Bundles/AutoCompletion.tmbundle/Support"  
end

require ENV['TM_SUPPORT_PATH'] + '/lib/escape'
require ENV['TM_BUNDLE_SUPPORT'] + '/wrapper_ctags'
require ENV['TM_BUNDLE_SUPPORT'] + '/shareopts'
require ENV['TM_BUNDLE_SUPPORT'] + '/support_classes'
require ENV['TM_BUNDLE_SUPPORT'] + '/ctags_parser'

class LineTests < Test::Unit::TestCase
  attr_reader :cppopts
  attr_accessor :tagparser
  def setEnv
    ENV['TMPDIR']="/var/folders/2I/2I9reMgJFGe1BF6k+QsEkk+++TI/-Tmp-/"
    ENV['TM_BUNDLE_PATH']="/Users/jaremy/Library/Application Support/TextMate/Bundles/AutoCompletion.tmbundle"
    ENV['TM_BUNDLE_SUPPORT']="/Users/jaremy/Library/Application Support/TextMate/Bundles/AutoCompletion.tmbundle/Support"
    ENV['TM_DIRECTORY']="/Users/jaremy/proj/autocomplete/words"
    ENV['TM_FILENAME']="words.cpp"
    ENV['TM_FILEPATH']="/Users/jaremy/proj/autocomplete/words/words.cpp"
    ENV['TM_SELECTED_FILE']="/Users/jaremy/proj/autocomplete/words/words.cpp"
    ENV['TM_SELECTED_FILES']="'/Users/jaremy/proj/autocomplete/words/words.cpp'"
    ENV['TM_LINE_NUMBER']="65"
    ENV['TM_COLUMNS']="109"
    ENV['TM_COLUMN_NUMBER']="12"

    ENV['TM_MODE']="C++"
    ENV['TM_PROJECT_DIRECTORY']="/Users/jaremy/proj/autocomplete/words"
    ENV['TM_SCOPE']="source.c++"
    ENV['TM_SUPPORT_PATH']="/Applications/Apps/TextMate.app/Contents/SharedSupport/Support"
    ENV['TM_SYS_HEADER_PATH']="/Users/jaremy/proj/fah/fah-work/:/Users/jaremy/proj/fah/libfah/:/opt/local/include/"
    ENV['TM_USR_HEADER_PATH']="/usr/include/"
  end
  
  def setup
    #setup ENV variables
    setEnv
    $errout = []

    @cppopts = { 
      :OBS => '\.', 
      :MOD => '::',
      :OBS! => ".", 
      :MOD! => "::",
      :TYPE => "CPP",
      :SYSTAGSDIR => ENV['TM_BUNDLE_SUPPORT'] + "/SystemTags/C++/",
      :WORD => '(?:(?:\w+::)*\*{0,2}\w+)', # match a complete namespace-variable name
      :HIDE => '_', # Characters to hide if found in beginning of result name
    }
    @tagparser = TagParser.new(cppopts)
  end
  def teardown
  end
  def setline(test)
    ENV['TM_CURRENT_LINE']=test
    ENV['TM_LINE_INDEX']=test.length.to_s 
    
    line, col = ENV['TM_CURRENT_LINE'], ENV['TM_LINE_INDEX'].to_i
    line = line[0..col-1]
    return line 
  end

  def check_array_ret(line, output)
    puts "LINE: '#{line}'"
    assert_nothing_thrown do
      candidates = tagparser.parse_input(line)
    end
    return res
  end
  def test_parse_lines
    line = "  new_word."
    control = ["_Alloc_hider",
     "_M_capacity",
     "_M_clone",
     "_M_destroy",
     "_M_dispose",
     "_M_grab",
     "_M_is_leaked",
     "_M_is_shared",
     "_M_leak_hard",
     "_M_length",
     "_M_mutate",
     "_M_p",
     "_M_refcopy",
     "_M_refcount",
     "_M_refdata",
     "_M_replace_aux",
     "_M_replace_dispatch",
     "_M_replace_safe",
     "_M_set_leaked",
     "_M_set_length_and_sharable",
     "_M_set_sharable",
     "_Raw_bytes_alloc",
     "_S_construct",
     "_S_create",
     "_S_empty_rep",
     "_S_empty_rep_storage",
     "_S_max_size",
     "_S_terminal",
     "allocator_type",
     "append",
     "assign",
     "at",
     "basic_string",
     "begin",
     "c_str",
     "capacity",
     "clear",
     "compare",
     "const_iterator",
     "const_pointer",
     "const_reference",
     "const_reverse_iterator",
     "copy",
     "data",
     "difference_type",
     "empty",
     "end",
     "erase",
     "find",
     "find_first_not_of",
     "find_first_of",
     "find_last_not_of",
     "find_last_of",
     "get_allocator",
     "insert",
     "iterator",
     "length",
     "max_size",
     "npos",
     "pointer",
     "push_back",
     "rbegin",
     "reference",
     "rend",
     "replace",
     "reserve",
     "resize",
     "reverse_iterator",
     "rfind",
     "size",
     "size_type",
     "substr",
     "swap",
     "traits_type",
     "value_type",
     "~basic_string"]
    doTest(line,control)
  end
  def test_std_ce
    line =  "std::ce"
    control = ["cerr"]
    doTest(line,control)
  end
  def test_infile
    line = " in_file.ge" 
    control = ["get", "getline", "getloc"]
    doTest(line,control)
  end
  def test_words
    line = "words."
    control = ["enter", "enter_one", "print", "print_one", "tree", "word"]
    doTest(line,control)
  end
           
  def test_ifstream
    line = "std::ifstream::"
    
    control = ["Init",
     "_Callback_list",
     "_M_add_reference",
     "_M_cache_locale",
     "_M_call_callbacks",
     "_M_callbacks",
     "_M_ctype",
     "_M_dispose_callbacks",
     "_M_exception",
     "_M_fill",
     "_M_fill_init",
     "_M_flags",
     "_M_fn",
     "_M_gcount",
     "_M_getloc",
     "_M_grow_words",
     "_M_index",
     "_M_init",
     "_M_ios_locale",
     "_M_iword",
     "_M_local_word",
     "_M_next",
     "_M_num_get",
     "_M_num_put",
     "_M_precision",
     "_M_pword",
     "_M_refcount",
     "_M_remove_reference",
     "_M_setstate",
     "_M_streambuf",
     "_M_streambuf_state",
     "_M_tie",
     "_M_width",
     "_M_word",
     "_M_word_size",
     "_M_word_zero",
     "_S_local_word_size",
     "_Words",
     "__ctype_type",
     "__filebuf_type",
     "__int_type",
     "__ios_type",
     "__istream_type",
     "__num_get_type",
     "__num_put_type",
     "__pf",
     "__streambuf_type",
     "adjustfield",
     "app",
     "ate",
     "bad",
     "badbit",
     "basefield",
     "basic_ifstream",
     "basic_ios",
     "basic_istream",
     "beg",
     "binary",
     "boolalpha",
     "char_type",
     "clear",
     "close",
     "copyfmt",
     "copyfmt_event",
     "cur",
     "dec",
     "end",
     "eof",
     "eofbit",
     "erase_event",
     "event",
     "event_callback",
     "exceptions",
     "fail",
     "failbit",
     "failure",
     "fill",
     "fixed",
     "flags",
     "floatfield",
     "fmtflags",
     "gcount",
     "get",
     "getline",
     "getloc",
     "good",
     "goodbit",
     "hex",
     "ignore",
     "imbue",
     "imbue_event",
     "in",
     "init",
     "int_type",
     "internal",
     "io_state",
     "ios_base",
     "iostate",
     "is_open",
     "iword",
     "left",
     "narrow",
     "oct",
     "off_type",
     "open",
     "open_mode",
     "openmode",
     "out",
     "peek",
     "pos_type",
     "precision",
     "putback",
     "pword",
     "rdbuf",
     "rdstate",
     "read",
     "readsome",
     "register_callback",
     "right",
     "scientific",
     "seek_dir",
     "seekdir",
     "seekg",
     "sentry",
     "setf",
     "setstate",
     "showbase",
     "showpoint",
     "showpos",
     "skipws",
     "streamoff",
     "streampos",
     "sync",
     "sync_with_stdio",
     "tellg",
     "tie",
     "traits_type",
     "trunc",
     "unget",
     "unitbuf",
     "unsetf",
     "uppercase",
     "what",
     "widen",
     "width",
     "xalloc",
     "~Init",
     "~basic_ifstream",
     "~basic_ios",
     "~basic_istream",
     "~failure",
     "~ios_base"]
           
    doTest(line,control)
  end
  
  def doTest(line,control)
    $errout = []
    begin
      candidates = tagparser.doCandidates("#{line}")
      candidates = candidates.collect do |t|
        k = t['kind']
        # k = t['signature'] if k == "function"
        t.name
      end
      result = candidates.uniq.sort
      
      assert_equal control, result
    rescue
      puts "\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
      puts "%%%%%%%% Error! line: '#{line}'"
      puts $errout*"\n"
      raise
    end
  end

end
  




