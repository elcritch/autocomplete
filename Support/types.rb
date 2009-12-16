if __FILE__ == $0  
  ENV['TM_BUNDLE_SUPPORT']=ENV['TM_PROJECT_DIRECTORY']
end

require ENV['TM_BUNDLE_SUPPORT'] + '/shareopts'
require ENV['TM_BUNDLE_SUPPORT'] + '/qualname'

class LangType
  include ShareOpts
  include QualifiedNameAccess
  
  attr_accessor :typename
  attr_accessor :generics
  attr_accessor :modifier
  attr_accessor :returntp
  attr_accessor :ctagkind
  
  def initialize(varname)
    configureOpts
    @typename = QualifiedName.new ""
    @generics = []
    @qualname = QualifiedName.new varname
  end
  def self.genre(kind)
  end
  def parse(decl, kind)
  end
  def generics_parser(dfn)
  end
  def basic?(vartype=nil)
  end
  def to_s
    name
  end
  def inspect
    res = "["
    res << "Name: #{@name})" if name
    res << "Type: #{@typename.namespace}"
    res << "]"
    return res
  end
end

class CPPType < LangType
  def self.genre(kind)
    case kind
    when "class", "namespace"
      tagkind = :class
    when "function", "prototype"
      tagkind = :function
    when "typedef", "variable", "externvar", "member", "local"
      tagkind = :variable
    when "enum", "enumerator", "union", "struct"
      tagkind = :container
    else
      eval "tagkind = :unknown_#{kind.to_s.slice(/\w+/)}"
    end
    return tagkind
  end
  
  def self.reducable?(kind)
    # TODO: how should this method be implemented? We need to know wether to continue reducing, 
    # or wether we should take a "class" or "container type"
    answer = false
    case kind
    when "class", "namespace"
      answer = true
    when "typedef"
      answer = true
    when "variable", "externvar", "member", "local"
      answer = false
    else
      answer = false
    end
    return answer
  end
  
  def parse(decl, kind)
    raise "CPPType Error: Incorrect declaration for '#{name}'" unless name == "" or decl.match( /#{name}/)
    @modifiers = stripModifiers!(decl)
    @ctagkind = CPPType.genre(kind)
    $errout << "CPPType:parse: mods: #{@modifiers} ctagkind: #{@ctagkind}" 
    case @ctagkind
    when :class
      raise "Unimplemented we don't parse classes/namespaces directly."
    when :function
      parse_function(decl)
    when :variable
      parse_types(decl)
    when :container
      parse_containers(decl)
    when :unknown_macro
      parse_macro(decl)
    else
      raise "Unimplemented CPP type: cannot parse: #{kind}. Please help by extending this program!"
    end
    
  end
  
  def parse_types(decl)
    # this should match a typedef with a type, generics and name
    # modifiers should be stripped out at this point
    regex_type = Regexp.new(/ 
            ^ [^\w]* \s* # remove extraneous leading chars
            ( #{opt[:WORD]} \s* (?:<.*>)?) \s* # match the type and generics type CPP specific?
            ( [\*\&]{0,2} ) \s* # match pointers and references
            ( #{opt[:WORD]} ) # name of the var, inc. pointer, 
            \s* [\;\(]? # and trailing spaces and semicolon or paren
    /x )
    match_type = regex_type.match decl
    type, reference, varname = match_type[1..-1]
    
    # $errout << "Parse type: #{decl}"
    # $errout << "match_type: #{match_type.to_a.inspect}"
    # $errout << "type '#{type.inspect}'"
    # $errout << "reference '#{reference.inspect}'"
    # $errout << "varname '#{varname.inspect}'"
    
    type.gsub!(/\s+/,'')
    type += reference unless reference.empty?
    
    res = generics_parser(type)
    
    @typename = res.typename
    @qualname = QualifiedName.new varname
    @generics = res.generics
  end
  
  def parse_function(decl)
    # Function pointers are 'rettype (*name)() ;'
    # Use iterative approach ... 
    # walla^
    # return nil if decl.match /\[#{opt[:WORD]}\]/
    
    decl.gsub!(/&/,'') # we don't _really_ care about & references do we??
    returntype, reference, name, signature = "","","",""

    regex_fncptr = Regexp.new( / 
          # (#{opt[:WORD]})? \s* # match return type
          # ([\*]{0,2}) \s*     # pointer or reference?
          \( (#{opt[:WORD]}) [^()]* \) \s*    # name
          \(( [^()]* )\)  # signature
          /x )          # end
    match_fncptr = regex_fncptr.match decl
    if match_fncptr
      # $errout << "Function: Pointer"
      # returntype, reference, 
      name, signature = match_fncptr[1..-1]
      returntype = decl.gsub(regex_fncptr,'').gsub(/[\s;]+/,' ')
      # return parse_function(name) if regex_fncptr.match name
    else
      # $errout << "Function: Regular"
      regex_func = Regexp.new( / 
                (#{opt[:WORD]}) \s* 
                (\*{0,2}) \s* 
                (#{opt[:WORD]}) 
                (\(.+\)) /x)
      match_func = regex_func.match decl
      returntype, reference, name, signature = match_func[1..-1]
    end
    returntype.strip!
    
    # $errout << "match: #{match_fncptr.to_a.inspect}"
    # $errout << "returntype '#{returntype}'"
    # $errout << "reference  '#{reference }'"
    # $errout << "name       '#{name      }'"
    # $errout << "signature  '#{signature }'"
    
    # returntype += reference if reference.is_a? String
    @returntp = returntype
    @typename = QualifiedName.new
    @qualname = QualifiedName.new name
    
  end
  
  def parse_containers(decl,kind)
    # not implemented yet
    # TODO: implement struct, union, enumerations...
    case kind
      when "struct"
      when "enum", "enumeration"
      when "union"
    end
  end
  def parse_macro(decl)
    # not implemented yet
  end
  
  def generics_parser(dfn)
    stripModifiers!(dfn)
    
    # $errout << "Generics: dfn: #{dfn}"
    # parse a definition type
    # returning a series of QualifiedName's
    # dfn = "name<generics,type>"
    dfn.slice!( /^ ( #{opt[:WORD]} )/x)
    res = CPPType.new ""
    res.typename = QualifiedName.new $1
    # we do a recursive generics check and also loop over elements in a 
    # generics definition
    if dfn.slice!(/^</)
      begin
        ret = generics_parser(dfn)
        res.generics << ret if ret
      end while dfn.slice!(/^,/)
      dfn.slice!(/^>/)
    end
    return res
  end
  
  def stripModifiers!(decl)
    # TODO: need to complete list?
    decl.strip!
    modifiers = "typedef|static|volatile|unsigned|signed|short|long|extern|extern \"C\"|extern 'C'" 
    modifier = []
    modifiers.split('|').each do |mod|
      decl.slice!(/\s*(#{mod})/)
      modifier << $1 if $1
    end
    return modifier
  end
  
  def atomic?(vartype=nil)
    # returns wether type is atomic or not
    basictypes = "void|wchar_t|int|double|char|float|bool"
    return basictypes.split('|').include?( @typename.name)
  end
  
  def kinds
    kinds = [
    "class",
    "enum",
    "enumerator",
    "externvar",
    "function",
    "macro",
    "member",
    "namespace",
    "prototype",
    "struct",
    "typedef",
    "union",
    "variable",
    ]
  end
  
  def inspect
    # return "Unknown typename" if @typename == nil
    # return "Unknown name" if name == nil
    res = "["
    res << "Name: #{name} " if name
    res << "Type: #{@typename.namespace}" unless @typename == nil
    if not @generics.empty?
      res << "<"
      for t in @generics do
        res << t.inspect << ", "
      end
      res.slice!(/,\s+$/)
      res << ">"
    end
    res << "]"
    return res
  end
end 
