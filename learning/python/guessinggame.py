#!/usr/bin/python
# 
# simple guessing game
# 
from random import randint

# Generates a number from 1 through 10 inclusive
random_number = randint(1, 10)
#print "debug: random number is: ", random_number
guesses_left = 3
print "+-------------+"
print "|Guessing game|"
print "+-------------+"
print
print "you have %d chances to guess a random number between 1 and 10" % guesses_left
# Start your game!
while guesses_left > 0:
    if guesses_left > 1:
        guess = int(raw_input("you have %d guesses left - enter guess: " % guesses_left))
    else:
        guess = int(raw_input("this is your last chance - enter guess: "))
    if guess == random_number:
        print "You win!"
        break
    else:
        if guesses_left > 1:
            print "Nope - try again..."
	else:
            print "Sorry..."
    guesses_left -= 1
else:
    print "You lose - It was %d! HAHAHA" % random_number

print
print "----------- testing -----------"
print
tries = 0
max_tries = 100
want = 10
random_number = 0
print "how many tries does it take to get %d from `randint` (giving up after %d)" % (want, max_tries)
print
while random_number != want or tries > 100:
    random_number = randint(1, 10)
    tries += 1
    print "(try#: %d): random number = %d - looking for '10'" % (tries, random_number)
    if random_number == want:
        print "`randint` produced the number %d in %d tries" % (want, tries)
        break
else:
    print "gave up after %d tries" % max_tries

print
print "----------- playing -----------"
print
tries = 0
max_tries = 100
random_guess = 0
random_number = randint(1, 10)
print "how many tries does it take for `randit` to match a random number (giving up after %d)" % max_tries
print
print "the random number is: %d." % random_number
print "let's see how long it takes to match it"
print
while random_number != random_guess or tries > 100:
    random_guess = randint(1, 10)
    tries += 1
    if random_guess < random_number:
        print "[try #: %d] random guess (%d) < random number = %d" % (tries, random_guess, random_number)
    elif random_guess > random_number:
        print "[try #: %d] random guess (%d) > random number = %d" % (tries, random_guess, random_number)
    else:
        print "[try #: %d] random guess (%d) = random number = %d" % (tries, random_guess, random_number)
        print "found it in %d tries!" % tries
	break
else:
    print "gave up after %d tries" % max_tries
    

