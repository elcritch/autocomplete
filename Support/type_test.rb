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

class FirstTests < Test::Unit::TestCase
  include ShareOpts
  
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
    
    @testlines = [
      # basic (Don't need these???)
      'const char ** const p6;        //  const pointer to       pointer to const char',
      'typedef char * PCHAR;',
      'int *q[5];',
      'node *root;',

      # typedef (Need these!!)
      'typedef std::map<std::string, stats_cmd_t> cmd_map_t',
      'typedef _BinClos<_Name, _ValArray, _Constant, _Tp, _Tp> _Closure; ',
      'typedef struct _GThread GThread;',
      '    typedef std::map<const std::string, SmartPointer<Option> > some_type;',
      '    typedef std::vector<SmartPointer<Option> > options_t;',
      
      # TODO: add enums!!
      
      # declaration/initializing..
      'SmartLock lock(job);',
      
      # basic function (need these)
      'void print_one(node *top);',

      # advanced function pointers ... maybe not??
      'void * (*a[5])(char * const, char * const);',
      'int (T::*fpt_t)(const Option &) ;',
      'int * (* (*fp1) (int) ) [10];',
      '    typedef int (T::*fpt_t)(const Option &);',
      '    typedef int (T::*fpt_noargs_t)();',
    ]
    
    ctags_kinds = [
      "class",
      "externvar",
      "function",
      "local",
      "member",
      "prototype",
      "typedef",
      "variable",
    ]
    
    ENV['DEBUG']="TRUE"
    # ENV['TRACE']="TRUE"

    @cppopts = { 
      :OBS => '\.', 
      :MOD => '::',
      :TYPE => "CPP",
      :SYSTAGSDIR => ENV['TM_BUNDLE_SUPPORT'] + "/SystemTags/C++/",
      :WORD => '(?:(?:\w+::)*\*{0,2}\w+)',
    }
    # @typeparse = CPPType.new(cppopts)
    TagOption.instance.setopts = @cppopts
    configureOpts
    
  end
  def teardown
    # puts
  end
  def setline(test)
    ENV['TM_CURRENT_LINE']=test
    ENV['TM_LINE_INDEX']=test.length.to_s 
    
    line, col = ENV['TM_CURRENT_LINE'], ENV['TM_LINE_INDEX'].to_i
    line = line[0..col-1]
    return line 
  end
  
  def check_array_ret(line, kind, control)
    # puts "Testing Declaration: '#{line}'"
    # assert_nothing_thrown do
    $errout = []
    begin
      cpptp = CPPType.new ""
      cpptp.parse line, kind
      # puts "\t\t=> #{cpptp.inspect}"
      assert_equal control, cpptp.inspect
    rescue
      puts
      puts $errout*"\n"
      raise
    end
    # end
    return cpptp
  end
  

  def test_basic
    kind = "variable"
    simple = {
      'static tree words;	// List of words we are looking for' => '[Name: words Type: tree]',
      '  int a;' => '[Name: a Type: int]',
      ' std::ifstream in_file; ' => '[Name: in_file Type: std::ifstream]',
      'cmd_map_t cmd_map;' => '[Name: cmd_map Type: cmd_map_t]',
    }
    simple.each_pair do |line,control|
      check_array_ret("#{line}",kind, control)
    end 
  end
  
  def containers
    tests = {
      'typedef struct _GThread GThread;' => '[Type :_GThread (name: GThread)]',
    }
    tests.each_pair do |line,control|
      assert_equal check_array_ret("#{line}","variable"), preset
    end 
  end
  
  def test_template
    kind = "variable"
    tests = {
        'std::map<std::string, stats_cmd_t> cmd_map_t;' => 
                '[Name: cmd_map_t Type: std::map<[Type: std::string], [Type: stats_cmd_t]>]',
    }
    tests.each_pair do |line,control|
      check_array_ret("#{line}",kind, control)
    end
  end
  
  def test_typedefs
    kind = "typedef"
    tpdefs = {
      # typedef (Need these!!)
      'typedef std::map<std::string, stats_cmd_t> cmd_map_t;' => 
          '[Name: cmd_map_t Type: std::map<[Type: std::string], [Type: stats_cmd_t]>]',
      
      'typedef _BinClos<_Name, _ValArray, _Constant, _Tp, _Tp> _Closure; ' => 
          "[Name: _Closure Type: _BinClos"+
          "<[Type: _Name], [Type: _ValArray], [Type: _Constant], [Type: _Tp], [Type: _Tp]>]",
      
      'typedef std::map<const std::string, SmartPointer<Option> > some_type;' => 
          '[Name: some_type Type: std::map<[Type: conststd::string], [Type: SmartPointer<[Type: Option]>]>]',
          
      '    typedef std::vector<SmartPointer<Option> > options_t;' => 
          '[Name: options_t Type: std::vector<[Type: SmartPointer<[Type: Option]>]>]',
    }
    
    tpdefs.each_pair do |line,control|
      check_array_ret("#{line}",kind, control)
    end 
  end
  def test_funcs
    kind = "function"
    funcs = {
      # basic function (need these)
      'void print_one(node *top);' => '[Name: print_one Type: ]',
    }
    
    funcs.each_pair do |line,control|
      check_array_ret("#{line}",kind, control)
    end 
  end
  def test_funcptrs
    kind = "function"
    results = []
    
    funcptrs = {
      # advanced function pointers ... maybe not??
      'void * (*a[5])(char * const, char * const);' => 
          ['[Name: *a Type: ]','void *'],
      'int (T::*fpt_t)(const Option &) ;' => 
          ['[Name: *fpt_t Type: ]','int'],
      'int * (* (*fp1) (int) ) [10];' => 
          ['[Name: *fp1 Type: ]','int * (* ) [10]'],
      '    typedef int (T::*fpt_t)(const Option &);' => 
          ['[Name: *fpt_t Type: ]','int'],
      '    typedef int (T::*fpt_noargs_t)();' => 
          ['[Name: *fpt_noargs_t Type: ]','int'],
    }
    
    funcptrs.each_pair do |line,control|
      result = check_array_ret("#{line}",kind, control[0])
      # puts $errout * "\n"
      assert_equal control[1], result.returntp
    end
    
    
  end

  def advanced

    test1 = 'float ( * ( *b()) [] )();        '      # b is a function that returns a 
                                           # pointer to an array of pointers
                                           # to functions returning floats.


    test2 = 'void * ( *c) ( char, int (*)());   '    # c is a pointer to a function that takes
                                           # two parameters:
                                           #     a char and a pointer to a
                                           #     function that takes no
                                           #     parameters and returns
                                           #     an int
                                           # and returns a pointer to void.
    test3 = 'void ** (*d) (int &, char **(*)(char *, char **));  '      
                                           # d is a pointer to a function that takes
                                           # two parameters:
                                           #     a reference to an int and a pointer
                                           #     to a function that takes two parameters:
                                           #        a pointer to a char and a pointer
                                           #        to a pointer to a char
                                           #     and returns a pointer to a pointer 
                                           #     to a char
                                           # and returns a pointer to a pointer to void
    test4 = 'float ( * ( * e[10]) (int &) ) [5];    '
                                           # e is an array of 10 pointers to 
                                           # functions that take a single
                                           # reference to an int as an argument 
                                           # and return pointers to
                                           # an array of 5 floats.
  end
  
    
end
  




