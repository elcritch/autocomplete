

w = "Some Long word::test"

pt = 'word::test'

w =~ /(#{pt})/x
puts "word #{$1}"