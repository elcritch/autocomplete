if __FILE__ == $0  
  ENV['TM_BUNDLE_SUPPORT']=ENV['TM_PROJECT_DIRECTORY']
end

require ENV['TM_BUNDLE_SUPPORT'] + '/shareopts'
require ENV['TM_BUNDLE_SUPPORT'] + '/wrapper_ctags'
require ENV['TM_BUNDLE_SUPPORT'] + '/types'


class Ectag
  include ShareOpts
  include QualifiedNameAccess
  
  attr_accessor :tag, :var
  
  def initialize(line)
    configureOpts
    @tag = line.split(/\t/)
    @qualname = QualifiedName.new @tag[0]
  end

  def get(info)
    return @tag.select { |x| x.match(/^#{info}:/) }.collect {|v| v =~ /\w+?:(.+)$/; $1}.first
  end
  def [](i)
    if i.is_a? Fixnum
      return @tag[i]
    elsif i.is_a? String
      return get(i)
    else
      raise "Incorrect Ectag lookup type! #{i.class}"
    end
  end
  def source
    return File.expand_path(@tag[1])
  end
  def to_s
    @tag.join('#') if @tag.is_a? Array
  end
  def inspect
    "Name: %skind: %s" % [ @tag[0].ljust(20), self.get('kind') ]
  end
  def <=>(a)
    return -1 if /#{opt[:MOD]}_+/.match(a[0]) and not /#{opt[:MOD]}_+/.match(@tag[0]) 
    return 1 if /#{opt[:MOD]}_+/.match(@tag[0]) and not /#{opt[:MOD]}_+/.match(a[0])
    return @tag[0] <=> a[0]
  end
  
  def get_line(file,pat,word)
    if pat.kind_of? String
      pat =~ /(\d+)/
      seek = $1.to_i
    else
      seek = pat
    end
    old = ""
    File.open(file).each_with_index do |line,pointer|
      if pointer+1 == seek
        old.sub!(/\/\/.*/,'')
        line.sub!(%r{\/\/.*$},'')
        
        # we add possibly multiple lines, then split on ';' 
        # then take what is before the last semicolon
        ret = (old.lstrip+line.rstrip).split(/;/)
        ret = ret.select {|e| e =~ / \b (?:\w+#{opt[:MOD]})* #{word} \b /x}
        
        return ret[0]
      end
      old = line
    end
    nil
  end
  def get_definition!(source_file=@tag[1], word=self.name )
    # find files ctag, then parse it looking for our word
    $errout << "get_definition!: finding declaration tag: '#{word}' '#{source_file}'"
    
    # if not %w{typedef local variable}.include? get('kind')
    #   raise "Error: cannot find declarations of type '#{get['kind']}'"
    # end
    
    decl = get_line(source_file,get('line'),word)
    raise "Error: cannot find declaration: #{word} in #{source_file}" unless decl
    
    $errout << "get_definition!: decl '#{decl.gsub("\n","")}'"
    @var = lang.new namespace
    @var.parse(decl,get('kind'))
    raise "Name or Parsing mismatch! #{@var.name}, #{name}" unless @var.name == name
  end
end

