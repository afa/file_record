require_relative 'boot'
p Test.new
p Test.new(a: 1, id:'1as', name: 'ttt')
p Test.find(1)
p Test.new(name: 'asd', data: 1.1).save
p Test.new(id: 2, name: 'asd', data: 2).save
p t2 = Test.find(2)
t2.data += 1
t2.save
p Test.find(2)
