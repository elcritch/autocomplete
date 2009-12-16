module Share
  require 'singleton'
  def hermit
    Hermit.instance
  end
  def hermit=(var)
    Hermit.instance.opt = 5
  end
  
  class Hermit
    include Singleton
    attr_accessor :opt
  end
end

class Ex1
  include Share
  def initialize
    Hermit.instance
  end
  def run
    hermit.opt = 5
  end
  def pr
    p hermit.opt
  end
end

class Ex2
  include Share
  def initialize
    Hermit.instance
  end
  def run
    hermit.opt = 4
  end
  def pr
    p hermit.opt
  end
  
end

ex1 = Ex1.new
ex2 = Ex2.new

ex1.run
ex1.pr
ex2.pr

ex2.run
ex1.pr
ex2.pr
