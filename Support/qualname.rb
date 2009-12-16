if __FILE__ == $0  
  ENV['TM_BUNDLE_PATH']   ="/Users/jaremy/Library/Application Support/TextMate/Bundles/AutoCompletion.tmbundle"
  ENV['TM_BUNDLE_SUPPORT']="/Users/jaremy/Library/Application Support/TextMate/Bundles/AutoCompletion.tmbundle/Support"  
end


class QualifiedName
  include ShareOpts

  def initialize(varname="")
    configureOpts
    return if not varname.is_a? String
    raise "Empty varname '#{varname}'" if varname == nil
    
    @allnames = varname.split(opt[:MOD])
    @name = @allnames.last
    @namespace = @allnames[0..-2]
    
    if @allnames == nil
      $errout << "QualifiedName: varname: #{varname}"
      raise "Trying to set null QualifiedName!"
    end
    
  end
  def name
    @name
  end
  def namespace
    @allnames * "#{opt[:MOD]}"
  end
  def to_s
    self.namespace
  end
  # def namespace?
  #   !@namespace.empty?
  # end
  def inspect
    ret = ""
    ret << "Allname: " << @allnames.inspect
    ret << " Name: " << @name if @name
    return ret
  end
  def addnamespace(var)
    nm = var.split(opt[:MOD])
    raise "Trying to overwrite old namespace" if not @namespace.empty?
    @namespace = nm if nm.is_a? Array
  end
  def _allnames
    @allnames
  end
end

module QualifiedNameAccess
  def name
    @qualname.name
  end
  def namespace
    @qualname.namespace
  end
  def name?(word)
    # $errout << "name?: #{@qualname.name} == #{word.name}"
    @qualname.name == word.name
  end
  def nameany?(word)
    # $errout << "nameany?: #{@qualname.namespace} == #{word.name} :: "
    (@qualname.namespace.match(/ \b #{word.name} \b /x) ) ? true : false
  end
  def namespace?(word)
    # $errout << "name?: #{@qualname.namespace} == #{word.namespace}"
    @qualname.namespace == word.namespace
  end
  
end
