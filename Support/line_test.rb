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
      :TYPE => "CPP",
      :SYSTAGSDIR => ENV['TM_BUNDLE_SUPPORT'] + "/SystemTags/C++/",
      :WORD => '(?:(?:\w+::)*\*{0,2}\w+)',
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

  # def example
  #   line = testlines
  #   res = tagparser.doCandidates(line)
  #   assert(2 - 1 == 2)  # should fail
  #   assert(1 - 1 == 0)  # should succeed
  #   assert(1 + 1 == 2, "Addition should work.")
  #   assert_equal([6,5,4,3,2,1], reverse_array(@array))
  #   assert_equal(30, @string.length)
  #   assert_equal(0, @fake_string.length)
  # end

  def check_array_ret(line, output)
    puts "LINE: '#{line}'"
    assert_nothing_thrown do
      res = tagparser.parse_input(line)
      assert_equal output, line
    end
    return res
  end
  def test_parse_lines
    testlines = {
      "  new_word." => 
          {:partial=>"", :parents=>[], :basename=>"new_word", :kind=>"."},
      "  std::word::long.new.ex" => 
          {:kind=>".", :partial=>"ex", :basename=>"std::word::long", :parents=>["new"]},
      "  std::word::long.new().func_return." => 
          {:parents=>["new", "func_return"],:kind=>".",:basename=>"std::word::long",:partial=>""},
      "std::ce" => 
          {:kind=>"::", :partial=>"ce", :basename=>"std", :parents=>[]},
      "short::part" => 
          {:kind=>"::", :partial=>"part", :basename=>"short", :parents=>[]},
      " in_file.ge" => 
          {:partial=>"ge", :parents=>[], :basename=>"in_file", :kind=>"."},
      "words." => 
          {:partial=>"", :parents=>[], :basename=>"words", :kind=>"."},
      "cmd_map." => 
          {:basename=>"cmd_map", :partial=>"", :parents=>[], :kind=>"."},
      "std::ifstream::" => 
          {:parents=>[], :kind=>"::", :basename=>"std::ifstream", :partial=>""},
    }
    
    testlines.each_pair do |line,control|
      $errout = []
      begin
        result = tagparser.parse_input("#{line}")
        assert_equal control, result
      rescue
        puts "\n%%%%% Error! line: '#{line}'"
        puts $errout*"\n"
        raise
      end
    end
  end

  def test_ectag
    etag = Ectag.new 'tree::node::left	/Users/jaremy/proj/autocomplete/words/words.cpp	20;"	kind:member	line:20	language:C++	class:tree::node	file:	access:private'
    assert_equal etag.name, "left"
    assert_equal etag.namespace, "tree::node::left"
  end 
  def test_getdef
    begin
      puts
      etag = Ectag.new 'words	/Users/jaremy/proj/autocomplete/words/words.cpp	49;"	kind:variable	line:49	language:C++	file:'
      puts "etag '#{etag}'"
      
      newtag = tagparser.reduce_type(etag)
      puts "newtag.inspect '#{newtag.namespace}'"
      
    rescue
      puts "Errors"
      puts $errout * "\n"
      raise
    end
  end
end
  




