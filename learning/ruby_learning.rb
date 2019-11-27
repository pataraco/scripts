#!/usr/bin/ruby

ls = %x{ls}.split
puts "#{ls}"
puts "#{ls[2]} and #{ls[4]}"
#3.times { puts "Ruby!" }
print "using '3.times' to print string 'Ruby!': "
3.times { print "Ruby! " }
puts
str = "Ruby!"
print "using '3.times' to print var 'str': "
#3.times { puts str }
3.times { print str + " " }
times = 3
print "using 'times.times' to print var 'str': "
times.times { print str + " " }
puts
print "'str' mangling; uppercase: " + str.upcase + " "
print "lowercase: " + str.downcase + " "
print "reverse: " + str.reverse
puts

puts "printing out 'str' (#{str}) using different loops..."
print "using 'for..loop'  : "
for i in 1..3
  print str + " "
end
puts

print "using 'while..loop': "
i = 3
while i > 0
  print str + " "
  i -= 1
end
puts

print "using 'loop'       : "
i = 3
loop do
  print str + " "
  i -= 1
  break if i == 0
end
puts

print "using 'until..loop': "
i = 3
until i == 0
  print str + " "
  i -= 1
end
puts
  
print "using 'array.each' : "
a = [1,2,3]
a.each do |i|
  print str + " "
end
puts

print "give a number (1-3): "
i = gets.chomp.to_i
if i == 3
  puts "looked for 3 and yes - the value of i is: #{i}"
elsif i == 2
  puts "looked for 2 and yes - the value of i is: #{i}"
elsif i == 1
  puts "looked for 1 and yes - the value of i is: #{i}"
else
  puts "couldn't find a value between 1-3 - you did not follow instructions"
end

str = "This is a test"
puts "using 'split' to split this string by spaces: #{str}"
words = str.split(" ")
words.each { |w| print "'#{w}' "}
puts

puts "using 'puts' to display the value of a string array"
str_ary = ["one","two","three"]
puts str_ary


puts "using 'puts' to display the value of a 2D array (one row at a time)"
my_2d_array = [["X","O","X"],["O","X","O"],["X","O","X"]]
print my_2d_array[0]
puts
print my_2d_array[1]
puts
print my_2d_array[2]
puts

puts "initializing a hash variable 'my_hash'"
my_hash = {
  "name" => "Patrick",
  "age"  => 40,
  "hungry?" => true
}
puts "using 'puts' to display the value of the hash 'my_hash' in it's entirety"
puts my_hash
puts "using 'puts' to display the individual values in the hash 'my_hash' using the keys"
puts "here's the value of 'name'    : #{my_hash["name"]}"
puts "here's the value of 'age'     : #{my_hash["age"]}"
puts "here's the value of 'hungry?' : #{my_hash["hungry?"]}"
puts "using 'puts' to display the individual values in the hash 'my_hash' using fetch method"
puts "here's fetching 'name'   : " + my_hash.fetch("name")
puts "here's fetching 'age'    : " + my_hash.fetch("age").to_s
#puts "here's fetching 'age'    : #{my_hash.fetch("age")}"	# this works!
puts "here's fetching 'hungry?': " + my_hash.fetch("hungry?").to_s
puts "here's fetching 'sex'    : " + my_hash.fetch("sex", "not set")
puts "here's fetching 'height' : " + my_hash.fetch("height") {|key| puts "the key '#{key}' is not set"}.to_s
my_hash = Hash.new

friends = ["Milhouse", "Ralph", "Nelson", "Otto"]
puts "using 'each' and 'puts' to display the values in an array"
friends.each { |x| puts "#{x}" }
family = { "Homer" => "dad", "Marge" => "mom", "Lisa" => "sister", "Maggie" => "sister", "Abe" => "grandpa", "Santa's Little Helper" => "dog" }
puts "using 'each' and 'puts' to display the values in a hash"
family.each { |x,y| puts "#{x}: #{y}" }

puts "give me some text please, I will count the freq of the words: "
text = gets.chomp
words = text.split(" ")
frequencies = Hash.new(0)
words.each { |word| frequencies[word] += 1 }
frequencies = frequencies.sort_by {|a, b| b }
frequencies.reverse!
frequencies.each { |word, frequency| puts word + " " + frequency.to_s }

puts "using a method that accepts variable amount of args to print out strings"
def what_up(greeting, *bros)
  bros.each { |bro| puts "#{greeting}, #{bro}!" }
end
what_up("What up", "Justin", "Ben", "Kevin Sorbo")

def prime(n)
  puts "#{n} is not an integer." unless n.is_a? Integer
  return unless n.is_a? Integer
  is_prime = true
  for i in 2..n-1
    if n % i == 0
      is_prime = false
    end
  end
  if is_prime
    puts "#{n} is prime!"
  else
    puts "#{n} is not prime."
  end
end
print "give me an integer - i'll tell you if it's a prime number: "
int = gets.chomp.to_i
prime(int)

puts "now determining if the number you gave is divisable by 5..."
def by_five?(n)
  return n % 5 == 0
end
puts by_five?(int)
if by_five?(int)
  puts "#{int} is divisable by 5"
else
  puts "#{int} is NOT divisable by 5"
end

# method that capitalizes a word
puts "created a method to capitalize a word..."
def capitalize(string) 
  puts "#{string[0].upcase}#{string[1..-1]}"
end
capitalize("ryan") # prints "Ryan"
capitalize("jane") # prints "Jane"
# block that capitalizes each string in the array
puts "but, i can just use the 'upcase' method"
["ryan", "jane"].each {|string| puts "#{string[0].upcase}#{string[1..-1]}"} # prints "Ryan", then "Jane"

my_array = [3, 4, 8, 7, 1, 6, 5, 9, 2]
my_array.sort!

fruits = ["orange", "apple", "banana", "pear", "grapes"]
puts fruits.sort.reverse
fruits.sort! { |a,b| b <=> a }

puts "showing 'object ids' diffs of strings and symbols..."
puts "string".object_id
puts "string".object_id
puts :symbol.object_id
puts :symbol.object_id

my_hash = {
  :one => 1,
  :two => 2,
  :three => 3,
}

:sasquatch.to_s      # ==> "sasquatch"
"sasquatch".to_sym   # ==> :sasquatch

strings = ["HTML", "CSS", "JavaScript", "Python", "Ruby"]
symbols = []
strings.each { |s| symbols.push(s.intern) }
strings.each { |s| symbols.push(s.to_sym) }
print strings
puts
print symbols
puts

movies = {
  :comedy => "South Park",
  :horror => "Rocky",
  :drama  => "Shrek",
}
#movies2 = {
#  comedy: "South Park",
#  horror: "Rocky",
#  drama:  "Shrek",
#}

#movies = {
#  The_Princess_Bride: 5,
#  Batman: 4,
#}

choice = nil
until choice == "quit" do
  puts "------------------------------"
  puts "what do you want to do? "
  puts "       add) add a movie to the DB"
  puts "    delete) delete a movie from the DB"
  puts "    update) update a rating of a movie in the DB"
  puts "   display) see the listing of movies"
  puts "      quit) quit this program"
  print "enter choice: "
  choice = gets.chomp
  case choice
  when "add"
    puts "What movie do you want to add?"
    title = gets.chomp
    if movies[title.to_sym].nil?
      puts "What rating do you want to give #{title} (1-5)?"
      rating = gets.chomp
      movies[title.to_sym] = rating.to_i
    else
      puts "#{title} is already in the DB with rating: #{movies[title.to_sym]}"
    end
  when "update"
    puts "What movie do you want to update?"
    title = gets.chomp
    if movies[title.to_sym].nil?
      puts "#{title} NOT FOUND in the DB - try adding it!"
    else
      puts "#{title} currently rated: #{movies[title.to_sym]}."
      puts "What NEW rating do you want to give #{title} (1-5)?"
      rating = gets.chomp
      movies[title.to_sym] = rating.to_i
    end
  when "display"
    puts "Here are the movies in the DB!"
    puts "------------------------------"
    movies.each { |t,r| puts "#{t}: #{r}" }
  when "delete"
    puts "What movie do you want to delete?"
    title = gets.chomp
    if movies[title.to_sym].nil?
      puts "#{title} NOT FOUND in the DB - try adding it!"
    else
      puts "deleting #{title} currently rated: #{movies[title.to_sym]}."
      movies.delete(title.to_sym)
    end
  when "quit"
    puts "goodbye!"
  else
    puts "Error!"
  end
end

################
print "give me a language to say 'hello' in: "
lang = gets.chomp
case lang
  when "English" then puts "Hello!"
  when "French" then puts "Bonjour!"
  when "German" then puts "Guten Tag!"
  when "Finnish" then puts "Haloo!"
  else puts "i dunno that lang"
end  
###################
favorite_book = nil
puts "the current val of 'favorite_book' is: #{favorite_book}"
favorite_book ||= "Cat's Cradle"
puts "now the val of 'favorite_book' is: #{favorite_book}"
#########
my_array = [0,1,2,3,4,5,6,7,8,9,10]
puts "printing even vals of array: #{my_array}"
my_array.each { |i| print "#{i} " if i%2==0 }
puts
my_array.each { |i| print "#{i} " if i.even? }
puts
###########
puts "using 'downto' to print vals '1 down to -5'..."
1.downto(-5) { |n| print "#{n} " }
puts
puts "using 'upto' to print vals 'L up to P'..."
"L".upto("P") { |c| print "#{c} " }
puts
######
#example: OBJECT.respond_to?(:SYMBOL)	# returns true|false
######
puts "initializing an array called 'alphabet'"
alphabet = ["a", "b", "c"]
puts "value of 'alphabet' array: #{alphabet}"
#alphabet.push("d") # Update me!
puts "pushing a value on to the array"
alphabet << "d"
puts "new value of 'alphabet' array: #{alphabet}"
puts "using 'respond_to' to see if you can use 'push' on an array"
puts "yes you can push to this array: #{alphabet}" if alphabet.respond_to?(:push)
puts "initializing an string called 'caption'"
caption = "A giraffe surrounded by "
puts "value of caption: '#{caption}'"
#caption += "weezards!" # Me, too!
puts "pushing a value on to the string"
caption << "leopards!"
puts "new value of caption: '#{caption}'"
# conditional assignments
prime_array = [] if prime_array.nil?	# instead of this
prime_array ||= []			# use this
# OOP
class Person
  attr_reader :name
  # creates
  # def name; @name; end
  attr_writer :name
  # creates
  # def name=(name); @name=name; end
  attr_accessor :job
  # creates both
  # def name; @name; end
  # def name=(name); @name=name; end
  def initialize(name)
    @name = name
  end
end
###
some = [1,2,3,10]
some_plus_one = some.collect {|x| x + 1}
# some_plus_one => [2,3,4,11]

my_nums = [1,2,3,4,5]
my_nums_squared = my_nums.collect { |n| n**2 }
my_nums.collect! { |num| num ** 2 }

def double (n)
  yield n
end
double(3) { |x| x*2 }

multiples_of_3 = Proc.new { |n| n % 3 == 0 }
(1..100).to_a.select(&multiples_of_3)

cube = Proc.new { |x| x ** 3 }
[1, 2, 3].collect!(&cube)    # ==> [1, 8, 27]
[4, 5, 6].map!(&cube)       # ==> [64, 125, 216]

floats = [1.2, 3.45, 0.91, 7.727, 11.42, 482.911]
round_down = Proc.new { |x| x.floor }
ints = floats.collect(&round_down)

def greeter
  yield
end
phrase = Proc.new { puts "Hello there!" }
greeter(&phrase)

hi = Proc.new { puts "Hello!" }
hi.call

strings = ["1", "2", "3"]
nums = strings.map(&:to_i)   # ==> [1, 2, 3]
numbers_array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
strings_array = numbers_array.map(&:to_s)    #==> ["1", "2", "3"...]

def lambda_demo(a_lambda)
  puts "I'm the method!"
  a_lambda.call
end
lambda_demo(lambda { puts "I'm the lambda!" })

strings = ["leonardo", "donatello", "raphael", "michaelangelo"]
symbolize = lambda { |parm| parm.to_sym }
symbols = strings.collect(&symbolize)
# => [:leonardo, :donatello, :raphael, :michaelangelo]

def batman_ironman_proc
  victor = Proc.new { return "proc: Batman will win!" }
  victor.call
  "proc: Iron Man will win!"
end
def batman_ironman_lambda
  victor = lambda { return "lambda: Batman will win!" }
  victor.call
  "lambda: Iron Man will win!"
end
puts batman_ironman_proc
puts batman_ironman_lambda
# ==> proc: Batman will win!
# ==> lambda: Iron Man will win!

my_array = ["raindrops", :kettles, "whiskers", :mittens, :packages]
symbol_filter = lambda { |i| i.is_a? Symbol }
symbols = my_array.select(&symbol_filter)
# ==> [:kettles, :mittens, :packages]

# modules
module Circle
  PI = 3.141592653589793
  def Circle.area(radius)
    PI * radius**2
  end
  def Circle.circumference(radius)
    2 * PI * radius
  end
end
# mixin's
# require modules
require 'date'
puts Date.today
# the following is not correct - think you have to use "include" in a 'class'
#include Date
#puts today
#class TheHereAnd
#  extend ThePresent
#end

