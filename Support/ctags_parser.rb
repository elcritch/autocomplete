require 'English'
require 'set'

if __FILE__ == $0  
  ENV['TM_BUNDLE_PATH']   ="/Users/jaremy/Library/Application Support/TextMate/Bundles/AutoCompletion.tmbundle"
  ENV['TM_BUNDLE_SUPPORT']="/Users/jaremy/Library/Application Support/TextMate/Bundles/AutoCompletion.tmbundle/Support"  
end

require ENV['TM_BUNDLE_SUPPORT'] + '/wrapper_ctags'
require ENV['TM_BUNDLE_SUPPORT'] + '/shareopts'
require ENV['TM_BUNDLE_SUPPORT'] + '/support_classes'
require ENV['TM_SUPPORT_PATH'] + '/lib/escape'


# TODO Make a class with all of this and move all the language specifics to a 
# loadable dictionary list, ie options[:filter] , etc to better modularize this
# code
class TagParser
  include ShareOpts
  # takes file, word string
  # returns an array of ctag definitions
  attr_reader :parsed
  
  def find_ctags(ctags_file, word, strict=true)
    # find files ctag, then parse it looking for our word
    # $errout << "find_ctags: word '#{word}'"
    
    zgrep = "zgrep -e '^[[:alnum:]:]*%s' \"%s\""
    if File.readable?(ctags_file) || File.readable?(ctags_file.concat('.gz'))
      cmd = zgrep % [ word.name, ctags_file]
      results = `#{cmd}`
      # $errout << "find_ctags: cmd '#{cmd}'"
      results = results.split("\n").collect {|line| Ectag.new line}
      # $errout << "find_ctags: results.length #{results.length}"
      @tag_cache += results
      results = results.select {|tag| tag.name?(word)} if strict
      results = results.select {|tag| tag.nameany(word)} if not strict
    else
      raise "Can't find ctags file #{ctags_file}"
    end
    return results
  end

  # will always returns array of tags or raise error
  def search_ctag(word,strict=true)
    $errout << "search_ctag: word.inspect '#{word.inspect}'"

    files = @paths.collect { |fl| CTAGS::hidden_ctags(fl) }
    if !@tag_cache.empty? # we add a caching ability, search this first
      if strict
        $errout << "search_ctag: word.inspect '#{word.inspect}' type:'#{word.class}'"
        tags = @tag_cache.select {|t| t.name?(word) }
      else
        tags = @tag_cache.select {|t| t.nameany?(word) }
      end
      return tags unless tags.empty?
    end
  
    for fl in files+opt[:SYSTAGS] do
      tags = find_ctags(fl, word, strict)
      return tags unless tags.empty?
    end
    $errout << "search_ctag: search_ctag word.inspect '#{word.inspect}'"
    $errout << "search_ctag: word '#{word.name}'"
    $errout << "search_ctag: files '#{files.inspect}'"
    $errout << "search_ctag: SYSTAGS '#{opt[:SYSTAGS].inspect}'"
    
    raise "Error: cannot find ctag: word: '#{word}'" if strict
    raise "Error: cannot find ctag: word fullname: '#{word.namespace}'" if not strict
  end

  # reduces type
  def reduce_type(varname)
    $errout << "reduce_type: varname: '#{varname}'"
    etags = find_ctags(CTAGS::hidden_ctags(@paths[0]),varname)
    etags = search_ctag(varname) if etags.empty?
    etag = etags.find{ |e| e['kind'].match(/class|namespace/) }
    etag = etags.first if not etag
    
    raise "Error: cannot find declaration in main file" unless etag
    $errout << "reduce_type: etags.inspect: #{etags.inspect}"
    $errout << "reduce_type: '#{etag.get('kind')}' genre:'#{lang.genre(etag['kind'])}' "
    depth = 0
    
    while etag and lang.genre(etag['kind']) == :variable
      $errout << "reduce_type: Reducing:"
      $errout << "reduce_type: Etag #{etag.inspect}"
      $errout << "reduce_type: Etag.var.inspect '#{etag.var.inspect}'\n"
      depth+=1
      raise "exceeded depth" if depth > 10
      etag.get_definition!
      
      # begin next iteration, find new ctag
      if etag.var.atomic?
        $errout << "reduce_type: ATOMIC type #{etag}"
        etags = []
      else
        etags = search_ctag(etag.var.typename) 
      end
      
      $errout << "reduce_type: etags.length: #{etags.length}"
      case etags.length
      when 1
        etag = etags.first
      when 0
        raise "No etags found?"
      else
        # don't know C++ well enough to know what types to do exactly...
        $errout << "reduce_type: ETAGS.INSPECT '#{etags.collect {|t| "\tRES: "+t.inspect}*"\n"}'"
        etag = etags.select {|t| lang.reducable?(t['kind']) }.first
      end
      $errout << "\n"
    end
  
    # $errout << "Final: var.etag #{etag.inspect}"
    return etag
  end

  def retreive_namespace(namespace)
    # if namespace.is_a? Ectag and namespace['kind'] == 'class'
    #   namespace = namespace.fullname
    # else
    #   namespace = namespace.first
    # end
    $errout << "retreive_namespace: #{namespace.inspect}"
    tags = search_ctag(namespace,strict=false)

    tags = tags.select {|t| !t[0].match /operator\s+/ }
    tags = tags.select {|t| !(t['access'] == "private") or (t['access'] == nil) }
  
    return tags
  end

  def coallate(etag)
    # need to coallate class together, find inheritence, call namespace on each?
    return retreive_namespace(etag) unless etag['inherits']
  
    # 1. find superclass ctag
    parents = etag['inherits'].split(',')
    $errout << "coallate: parents.split: '#{parents}'"
    ctags = parents.collect do |p|
      parent = QualifiedName.new p
      # $errout << "coallate: parents.class '#{p.class}'"
      $errout << "coallate: parents.inspect '#{p.inspect}'"
      search_ctag(parent) 
    end.flatten # this is expensive yes?
    
    unless ctags.empty?
      ptag = ctags.select {|t| t['kind'] == "class" or t['kind'] == "namespace" }
      ptag = ctags.select {|t| %w{class namespace}.include? t['kind'] }
      # kinds = "prototype" # don't know C++ well enough to know what types...
    end
  
    # 2. call retreive_namespace
    results = ptag.collect{ |p| coallate(p) }.flatten
    namespace = retreive_namespace(etag) 
    # $errout << "coallate: namespace: #{namespace.collect {|n| n.inspect+"\n"} }"
    return namespace + results
  end

  def retreive_candidates(etag)
    # now to find the complete namespace for this tag
    $errout << "retreive_candidates: Trying to retreive namespace candidates..."
    $errout << "retreive_candidates: etag: #{etag.class} #{etag.inspect}"
    
    namespace = [] # contains all the namespaces
    if lang.genre(etag['kind']) == :class
      namespace += coallate(etag)
    end
    namespace.sort!
    # $errout << "namespace \n#{namespace.collect {|t| t.inspect.to_s}.join("\n") }"
  end

  def format_candidates(candidates,partial)
    # $errout << "partial '#{partial}'"
    unless partial.empty?
      # select names that begin with our partial selection
      candidates = candidates.select{ |t| t.name.match /^ #{partial} /x }
    end
    return candidates.uniq
  end

  def initialize(options)
    TagOption.instance.setopts = options
    eval "TagOption.instance.setlang = #{options[:TYPE]}Type"
    configureOpts
    $errout = [] unless global_variables.include? "$errout"
    
    opt[:SYSTAGS] = [] unless opt[:SYSTAGS].is_a? Array
    opt[:SYSTAGS] += Dir.glob( File.join(opt[:SYSTAGSDIR],'*_ctags.gz') )
    @tag_cache = Set.new
    
    # set local vars
    @currfile = ENV['TM_FILEPATH']
    
    CTAGS::update_ctags(ENV['TM_PROJECT_DIRECTORY'])
    
    @hidden_file = CTAGS::hidden_ctags(@currfile)
    proj_paths = CTAGS::list_proj_files(ENV['TM_PROJECT_DIRECTORY'])
    @syspaths = opt[:SYSTAGS]
    @paths = [File.expand_path(@currfile)] + proj_paths
  end
  
  def parse_input(line)
    # remove any arguements to a class/function. This info could be used for type information later
    line.gsub!(/\s+/,'')
    line.gsub!(/ \( [^\(\)]* \) /x,'')

    # line =~ / (?: ((?:\w+ #{@mod})+ \w+ ) [\w\(\)\[\]#{@mod}]* ){0,1} # complicated, gets initial package
    regex_line = Regexp.new( / 
        ( (?:\w+ #{opt[:MOD]})*? \w+ )?   # complicated, gets initial package
        ( (?: \w* #{opt[:OBS]})*? \w* )    # get  list of parent objects
        (#{opt[:OBS]}|#{opt[:MOD]}) (\w*)     # get type of end paren and any partial words
    $/x) 
    
    match_line = regex_line.match line
    
    $errout << "match_line: #{match_line.to_a.inspect}"
    
    base, parents, kind, partial = match_line.to_a[1..-1]
    base ||= ""
    parents ||= ""
    kind ||= ""
    partial ||= ""

    # base = base.split(/#{opt[:MOD]}/) if package
    parents.slice!(/^#{opt[:OBS]}/) if parents
    parents = parents.split(/#{opt[:OBS]}/) if parents
    
    if not kind
      raise "Parse_input Error: package '#{package}',parents '#{parents}'"\
        "partial '#{partial}',kind '#{kind}'" 
    end
    input = { 
      :basename => base, 
      :parents => parents, 
      :partial => partial,
      :kind => kind,
    }
    $errout << "Line Input: #{input.inspect}"
    
    if base.empty? and parents.empty? and partial.empty? and kind.empty?
      raise "Error in Parsing input line" 
    end
    
    return input
  end
  
  def doCandidates(line)
    # get the current location and line

    # For sake of brevity, we'll just take the word as before the current index 
    # and require that the current marker be either a '.' or '::'
    
    # perform reduction
    parsed = parse_input(line)
    @parsed = parsed
    
    # case parsed[:kind] 
    #   
    #   when opt[:MOD].gsub("\\","")
    #     # for a module type we just need to search all ctags from system...
    #     word = parsed[:basename]
    #     var = QualifiedName.new(word)
    #     candidates = search_ctag(var)
    #     
    #   when opt[:OBS].gsub("\\","")      
        # this should reduce all "parents" using the resulting types to get accurate output...
        # e.g., use the "namespace" tags of the parents to properly reduce the type
        word = parsed[:basename]
        var = QualifiedName.new(word)
        tag = reduce_type(var)
        # tags = search_ctag(var)
        # tags.each do |t|
        #   $errout << "doCandidates: tag: #{t.inspect}"
        #   $errout << "doCandidates: tag: #{t.class}"
        # end
        candidates = retreive_candidates(tag)
    #   else
    #     puts "parsed[:kind] '#{parsed[:kind]}'"
    #     puts "opt[:OBS]  '#{opt[:OBS] }'"
    #     puts "opt[:MOD] '#{opt[:MOD]}'"
    #     raise "Error"
    # end

    res = format_candidates(candidates,parsed[:partial])
    return res
  end
  
end



