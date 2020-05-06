#!/usr/bin/python

from __future__ import print_function
from string import Template
from math import sqrt
from math import *

# builtins - todo - read about - play with
#   - any()
#   - collections() | deque()
#   - uuid()

variable = "value"


def function():
    global variable
    variable = "modified value"


function()
print(variable)

import boto3


# boto3 stuff (BEGIN)
def do_some_boto_stuff():
    ec2_client = boto3.client("ec2")
    ec2_resource = boto3.resource("ec2")
    describe_instances_output = ec2_client.describe_instances()
    instances = describe_instances_output.get("Reservations")
    for instance in instances:
        instance_dict = instance.get("Instances")[0]
        instance_resource = ec2_resource.Instance(instance_dict["InstanceId"])
        print(
            "instance id: %s  state: %s  type: %s"
            % (
                instance_resource.id,
                instance_resource.state["Name"],
                instance_resource.instance_type,
            )
        )
        print(
            "INSTANCE ID: %s  STATE: %s  TYPE: %s"
            % (
                instance_dict["InstanceId"],
                instance_dict["State"]["Name"],
                instance_dict["InstanceType"],
            )
        )
        instance_resource.modify_attribute(DisableApiTermination=False, DryRun=True)
        instance_resource.terminate(DryRun=True)
# boto3 stuff (END)

# argparse stuff (BEGIN)
import argparse

parser = argparse.ArgumentParser(prog="spam")
parser.add_argument(
    "-v",
    "--version",
    action="version",
    version="program: %%(prog)s - version: %s" % "1.2.3",
)
# _VersionAction(
#   option_strings=['-v', '--version'],
#   dest='version',
#   nargs=0,
#   const=None,
#   default='==SUPPRESS==',
#   type=None,
#   choices=None,
#   help="show program's version number and exit",
#   metavar=None)
parser.parse_args(["--version"])
# program: spam - version: 1.2.3
# argparse stuff (END)


# function stuff (begin)
def add(a, b):
    return a + b


def sub(a, b):
    return a - b


func_calls = [(add, (4, 5)), (sub, (6, 3))]
for func, args in func_calls:
    func(*args)
# 9
# 3


def str_to_dict(string):
    try:
        k, v = string.split("=", 1)
    except ValueError:
        raise argparse.ArgumentTypeError("%s does not match KEY=VALUE format." % string)
    return dict(k=v)
# function stuff (end)


### misc stuff (begin) ###
my_int = 7
my_float = 1.23
my_bool = True
print(my_int, my_float, my_bool)
print(my_int + my_float + my_bool)
sum = my_int + my_float
prod = my_int * my_float
diff = my_int - my_float
div = my_int / my_float
exp = my_int ** my_float
mod = my_int % my_float
print(sum, prod, diff, div, exp, mod)
print(
    "sum = {sum}\nprod = {prod}\ndiff = {diff}\ndiv = {div}\nexp = {exp}\nmon = {mod}".format(
        **locals()
    )
)
### misc stuff (end) ###


### strings and string formatting (begin) ###
# from __future__ import print_function  # needed for Python2.x
my_string = "String"
# 3rd_letter = "Monty"[2]
# 2nd_letter = my_string[1]
# print 3rd_letter, 2nd_letter
print(my_string, len(my_string), str(my_bool))
print(my_string, len(my_string), my_string.lower(), my_string.upper(), str(my_bool))
str1 = "Camelot"
str2 = "place"
print("Let's not go to %s. 'Tis a silly %s." % (str1, str2))
print("Let's not go to %(p)s. 'Tis a silly %(n)s." % {"p": str1, "n": str2})
print("Let's not go to %(p)s. 'Tis a silly %(n)s." % dict(p=str1, n=str2))
print("Let's not go to {}. 'Tis a silly {}.".format(str1, str2))
print("Let's not go to {p}. 'Tis a silly {n}.".format(n=str2, p=str1))
print("Let's not go to {str1}. 'Tis a silly {str2}.".format(**locals()))
print(f"Let's not go to {str1}. 'Tis a silly {str2}.")       # Python 3.x
### strings and string formatting (end) ###

exit("all done")  # EXIT - STOP TESTING!!!



# from string import Template
t = Template("Let's not go to $p. 'Tis a silly $n.")
t.substitute(p=str1, n=str2)
name = raw_input("What is your name? ")
print("nice to meet you %s!" % name)
print("hi %s, nice to meet you %s!" % (name, name))
original = raw_input("Enter a word: ")
if len(original) > 0 and original.isalpha():
    print("thanks for the word: %s" % original)
    print(original)
else:
    print("seriously? you didn't give me shit!")
    print("empty")

print(original[1 : len(original)])
print(original[1 : len(original) - 1])
print(original[1:4])
print(original[:2])
print(original[2:])

# generic import
import math

print(math.sqrt(25))

# function import
# from math import sqrt
print(sqrt(25))

# universal import
# from math import *
import math  # Imports the math module

everything = dir(math)  # Sets everything to a list of things from math
print(everything)  # Prints 'em all!
print(type(5))
print(type(5.0))
print(type("five"))
print(type(True))
print(type([1, 2, "three", "four", 5]))
print(type({"one": 1, "two": 2, "three": 3, "four": 4, "five": 5}))
#
letters = ["a", "b", "c"]
letters.append("d")
print(len(letters))
print(letters)
#
animals = ["ant", "bat", "cat"]
print(animals.index("bat"))  # => 1
animals.insert(1, "dog")
print(animals)  # ["ant", "dog", "bat", "cat"]

# lists
LIST = [1, 2, 5, 3, 4, 8]
for var in LIST:
    print("%s * 2 = %s" % (var, var * 2))
LIST.sort()
LIST.remove(5)
N = [1, 2, 4]
N.append(7)  # N = [1, 2, 4, 7] (adds value to end)
N.pop(1)     # N = [1, 4, 7]    (removes element 1 - returns "2")
N.remove(4)  # N = [1, 7]       (removes matching item)
del N[1]     # N = [1]          (removes element 1 - returns nil)
# range (start, end, step)
range(6)        # => [0, 1, 2, 3, 4, 5]
range(1, 6)     # => [1, 2, 3, 4, 5]
range(1, 6, 3)  # => [1, 4]
LIST = [3, 4, 25, 6, 1]
for i in range(len(LIST)):
    print(LIST[i])
board = []
for i in range(5):
    board.append(["X"] * 5)
print(board)
for row in board:
    print("-".join(row))
L1 = [1, 2, 5, 3]
L2 = L1      # copies the pointer to L1
L3 = L1[:]   # duplicates L1
L2[0] = 'a'  # L1 == L2 => ['a', 2, 5, 3]
L3[0] = 'a'  # L1 != L3 => ['a', 2, 5, 3]



### dicts (begin) ###
DICT_A = {}  # initialize a dict()
DICT_B = dict()  # better(?) way to initialize a dict()
DICT_C = dict(one=1, two="2")  # => dict_c = {'one': 1', two': '2'}
RESIDENTS = {"Puffin": 104, "Sloth": 105, "Burmese Python": 106}
del residents["Burmese Python"]
puffins = RESIDENTS.get("Puffin")  # better than "RESIDENTS['Puffin']"
### dicts (begin) ###


### while loop (begin) ###
count = 0
while count < 5:
    print("Hello World!")
    count += 1
else:
    print("Goodbye")
### while loop (end) ###

### for loop (begin) ###
LIST = [1, 2, 3, 4]
for n in LIST:
    print(n)
LIST = ["one", "two", "three", "four"]
for i, v in enumerate(LIST):
    print(i, "-", v)
list1 = [1, 2, 3, 4, 5]
list2 = ["one", "two", "three", "four", "five"]
for a, b in zip(list1, list2):
    print(a, b)
else:
    print("Bye")
### for loop (begin) ###


### print with no CR (newline) (begin) ###
# use "," to append (print no CR) [python 2.x]
# print "hello",
# print "world!"
# --- --- ---
print("hello", end="")
print("world!")
### print with no CR (newline) (end) ###


#### list/dict/set comprehensions (begin) ###
even_squares = [x ** 2 for x in range(1, 11) if (x % 2) == 0]
my_list = range(16)
print(filter(lambda x: x % 3 == 0, my_list))
languages = ["HTML", "JavaScript", "Python", "Ruby"]
print(filter(lambda w: w == "Python", languages))
###
my_list = [i ** 2 for i in range(1, 11)]
# --- --- ---
name_list = [
    {"first": "Patrick", "last": "Raco"},
    {"first": "Tim", "last": "Holiday"},
    {"first": "Scott", "last": "Benedict"},
]
print([name["first"] for name in name_list])
# ["Patrick", "Tim", "Scott"]
print([name["last"] for name in name_list])
# ["Raco", "Holiday", "Benedict"]
# --- --- ---
my_list = [1, 2, 3, 4, 5]
do_calc_list = [2, 3, 5]
sq_list = [x**2 for x in my_list]                          # [1, 4, 9, 16, 25]
even_sq_list = [x**2 for x in my_list if x%2==0]           # [4, 16]
do_sq_list = [x**2 for x in my_list if x in do_calc_list]  # [4, 9, 25]
# --- --- ---
list_stats = [('age', 37), ('wt', 195), ('ht', 201)]
dict_stats = {key:val for (key, val) in list_stats}
# {'age': 37, 'wt': 195, 'ht': 201}
list_of_lists = [[0], [3.4, 2.3], ['a'], ['x', 'y', 'z']]
flattened_list = [ v for l in list_of_lists for v in l]
# [0, 3.4, 2.3, 'a', 'x', 'y', 'z']
# --- --- ---
my_list = [1, 5, -3]
all([v > 0 for v in my_list])  # False
any([v > 0 for v in my_list])  # True
# --- --- ---
my_set = {'PAR', 'ATR', 'GAR'}
any([v == 'PAR' for v in my_set])  # True
#### list/dict comprehensions (end) ###


#######################
my_file = open("output.txt", "r+")
for i in my_list:
    my_file.write(str(i) + "\n")
my_file.close()
another_file = open("text.txt", "r")
print(another_file.read())
another_file.close()
a_file = open("text.txt", "r")
print(a_file.readline())
a_file.close()
with open("text.txt", "w") as textfile:
    textfile.write("Success!")
if not textfile.closed:
    textfile.close()


###################
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
    if counts[elem] > max_val:
        max_key = elem
        max_val = counts[elem]
no_2_del = 0
for k in counts.keys():
    if k != max_key:
        no_2_del += counts[k]

print(no_2_del)


# Comparing: iterables, list comprehension, indexing, unpacking
#
# |type |iter|list cp|index|unpack|
# |-----+ ---+-------+-----+------|
# |list |  Y |   Y   |  Y  |   Y  |
# |set  |  Y |   Y   |  N  |   Y  |
# |tuple|  Y |   Y   |  Y  |   Y  |
# |dict |  Y |   Y   |  Y  |   Y  |
