#!/usr/bin/python

"""
This program rolls a pair of dice and asks the user to guess a number.
Based on the user's guess, the program should determine a winner.
If the user's guess is greater than the total value of the dice roll, they win!
Otherwise, the computer wins.

The program should do the following:

1. Randomly roll a pair of dice
2. Add the values of the roll
3. Ask the user to guess a number
4. Compare the user's guess to the total value
5. Decide a winner (the user or the program)
6. Inform the user who the winner is
"""

from random import randint
from time import sleep

def get_user_guess():
    user_guess = int(raw_input("guess a number of the roll: "))
    return user_guess

def roll_dice(number_of_sides):
    print "calculating the max value... ",
    sleep(1)			# don't really need this, just adding for effect
    max_val = number_of_sides * 2
    print "done"
    user_guess = get_user_guess()
    #if user_guess > max_val:
    while user_guess > max_val:
        #print "the maximum posssible value is: " + str(max_val)
        print "the maximum posssible value is: %d" % max_val
        user_guess = get_user_guess()
    else:
        print "rolling the dice... ",
        first_roll = randint(1, number_of_sides)
        second_roll = randint(1, number_of_sides)
        sleep(2)			# don't really need this, just adding for effect
        print "done"
        print "the computer rolled a %d and %d" % (first_roll, second_roll)
        sleep(1)			# don't really need this, just adding for effect
        total_roll = first_roll + second_roll
        print "the total is %d and you guessed a %d" % (total_roll, user_guess)
        sleep(1)			# don't really need this, just adding for effect
        if user_guess == total_roll:
            print "you WON! you guessed correctly! Congrats!"
	elif user_guess < total_roll:
	    print "sorry you lost - you guessed too low"
	else:
	    print "sorry you lost - you guessed too high"

print "welcome to the dice guessing game!"
print "the computer is going to roll 2 dice and you try to guess the sum"
print
print "first, how many sides dice do you want to use?"
sides = int(raw_input("	Enter a number: "))
roll_dice(sides)
