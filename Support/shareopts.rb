module ShareOpts
  require 'singleton'
  attr_accessor :opt
  attr_accessor :lang
  
  def configureOpts
    self.opt = TagOption.instance.opt
    self.lang = TagOption.instance.lang
  end
  
  class TagOption
    include Singleton
    attr_reader :opt
    attr_reader :lang
    def setopts=(var)
      @opt = var
    end
    def setlang=(var)
      @lang = var
    end
  end
  
end
