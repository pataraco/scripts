#!/usr/bin/python

my_int = 7
my_float = 1.23
my_bool = True
my_string = "String"
print my_int, my_float, my_bool
print my_int+my_float+my_bool
sum = my_int + my_float
prod = my_int * my_float
diff = my_int - my_float
div = my_int / my_float
exp = my_int ** my_float
mod = my_int % my_float
print sum,prod,diff,div,exp,mod
#3rd_letter = "Monty"[2]
#2nd_letter = my_string[1]
#print 3rd_letter,2nd_letter
print my_string,len(my_string),str(my_bool)
print my_string,len(my_string),my_string.lower(),my_string.upper(),str(my_bool)
string_1 = "Camelot"
string_2 = "place"
print "Let's not go to %s. 'Tis a silly %s." % (string_1, string_2)
name = raw_input("What is your name? ")
print "nice to meet you %s!" % name
print "hi %s, nice to meet you %s!" % (name,name)
original = raw_input("Enter a word: ")
if len(original) > 0 and original.isalpha():
    print "thanks for the word: %s" % original
    print original
else:
    print "seriously? you didn't give me shit!"
    print "empty"

print original[1:len(original)]
print original[1:len(original)-1]
print original[1:4]
print original[:2]
print original[2:]
# generic import
import math
print math.sqrt(25)
# function import
from math import sqrt
print sqrt(25)
# universal import
from math import *
import math            # Imports the math module
everything = dir(math) # Sets everything to a list of things from math
print everything       # Prints 'em all!
print type(5)
print type(5.0)
print type("five")
print type(True)
print type([1,2,'three','four',5])
print type({'one':1,'two':2,'three':3,'four':4,'five':5})
#
letters = ['a', 'b', 'c']
letters.append('d')
print len(letters)
print letters
#
animals = ["ant", "bat", "cat"]
print animals.index("bat")	# => 1
animals.insert(1, "dog")
print animals			# ["ant", "dog", "bat", "cat"]
# list
list = [1,2,5,3,4,8]
for var in list:
    print "%s * 2 = %s" % (var,var*2)
list.sort()
list.remove(5)
# dictionary
residents = {'Puffin' : 104, 'Sloth' : 105, 'Burmese Python' : 106}
del residents['Burmese Python']
# lists
n = [1,2,4]
n.append(7)	# n = [1,2,4,7]	(adds value to end)
n.pop(1)	# n = [1,4,7]	(removes element 1 - returns "2")
n.remove(4)	# n = [1,7]	(removes matching item)
del(n[1])	# n = [1]	(removes element 1 - returns nil)
# range (start,end,step)
range(6)	# => [0,1,2,3,4,5]
range(1,6)	# => [1,2,3,4,5]
range(1,6,3)	# => [1,4]
list = [3,4,25,6,1]
for i in range(len(list)):
    print list[i]
board = []
for i in range(5):
    board.append(['X']*5)
print board
for row in board:
    print "-".join(row)
# while loop
count = 0
while count < 5:
    print "Hello World!"
    count += 1
else:
    print "Goodbye"
# for loop
list = [1,2,3,4]
for n in list:
    print n
list = ["one","two","three","four"]
for i, v in enumerate(list):
    print i, "-", v
list1 = [1,2,3,4,5]
list2 = ["one","two","three","four","five"]
for a, b in zip(list1,list2):
    print a, b
else:
    print "Bye"
# use "," to append (print no CR)
print "hello",
print "world!"
###
even_squares = [x**2 for x in range(1,11) if (x%2)==0]
my_list = range(16)
print filter(lambda x: x % 3 == 0, my_list)
languages = ["HTML", "JavaScript", "Python", "Ruby"]
print filter(lambda w: w=="Python", languages)
###
my_list = [i**2 for i in range(1,11)]
my_file = open("output.txt", "r+")
for i in my_list:
    my_file.write(str(i)+"\n")
my_file.close()
another_file = open("text.txt", "r")
print another_file.read()
another_file.close()
a_file = open("text.txt", "r")
print a_file.readline()
a_file.close()
with open("text.txt", "w") as textfile:
    textfile.write("Success!")
if not textfile.closed:
    textfile.close()

###################33
elems = int(raw_input())
array = map(int, raw_input().split())

max_key = 0
max_val = 0
counts = {}
for elem in array:
    if elem in counts.keys():
        counts[elem] += 1
    else:
        counts[elem] = 1
    if counts[elem] > max_val
        max_key = elem
        max_val = counts[elem]
no_2_del = 0
for k in counts.keys():
    if k != max_key:
        no_2_del += counts[k]
        
print no_2_del
#######################
from __future__ import print_function
print('This is {}'.format('fun'))
print('This is {}'.format('fun'), end='')

print 'This is %s' % 'fun'
#######################
name_list=[{'first':'Patrick','last':'Raco'},{'first':'Tim','last':'Holiday'},{'first':'Scott','last':'Benedict'}]
[name['first'] for name in name_list]
['Patrick', 'Tim', 'Scott']
[name['last'] for name in name_list]
['Raco', 'Holiday', 'Benedict']
