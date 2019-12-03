#!/usr/bin/python

"""
Simple Rock-Paper-Scissors game!

The program should do the following:

1. Prompt the user to select either Rock, Paper, or Scissors
2. Instruct the computer to randomly select either Rock, Paper, or Scissors
3. Compare the user's choice and the computer's choice
4. Determine a winner (the user or the computer)
5. Inform the user who the winner is
6. Best 2 outta 3
    a. If the user loses, ask if they want to continue and try "2 outta 3"
    b. If the computer loses, randomly chose to continue and try "2 outta 3"
"""

from random import randint
from time import sleep

MAX_TRIES = 3
OPTIONS = ["R", "P", "S"]
WORDS = ["Rock", "Paper", "Scissors"]
LOSS_MESSAGE = "You lose ;("
WIN_MESSAGE = "You WIN!  :)"
TIE_MESSAGE = "Tie - try again..."

def decide_winner(user_choice, cpu_choice):
# return codes:
#  0 - user wins
#  1 - cpu wins
#  2 - tie or bad choice - try again

    user_choice_index = OPTIONS.index(user_choice)
    cpu_choice_index = OPTIONS.index(cpu_choice)
    #print "your choice: %s  -  computer's choice: %s" % (user_choice,cpu_choice)
    print "your choice: %s  -  computer's choice: %s" % (WORDS[user_choice_index],WORDS[cpu_choice_index])
    sleep(1)			# don't really need this, just adding for effect
    if user_choice_index == cpu_choice_index:
        print TIE_MESSAGE
        return 2
    elif user_choice_index == 0 and cpu_choice_index == 2:
        print WIN_MESSAGE
    elif user_choice_index == 1 and cpu_choice_index == 0:
        print WIN_MESSAGE
    elif user_choice_index == 2 and cpu_choice_index == 1:
        print WIN_MESSAGE
    elif user_choice_index > 2:
        print "you made a bad choice - try again"
        return 2
    else:
        print LOSS_MESSAGE
        return 1
    return 0

def play_RPS():
    # initialize
    times_played = 0
    user_wins = 0
    cpu_wins = 0

    print
    print "welcome to the 'Rock, Paper, Scissors' game!"
    print
    while times_played < MAX_TRIES:
       print "you can go first... then the computer is going to try to beat you"
       user_choice = raw_input("Please enter your choice ([R]-Rock, [P]-Paper, [S]-Scissors): ").upper()
       while user_choice != "R" and user_choice != "P" and user_choice != "S":
           print "bad choice!"
           user_choice = raw_input("Please enter your choice ([R]-Rock, [P]-Paper, [S]-Scissors): ").upper()
       sleep(1)			# don't really need this, just adding for effect
       print "computer selecting... "
       sleep(1)			# don't really need this, just adding for effect
       cpu_choice = OPTIONS[randint(0, len(OPTIONS)-1)]
       result = decide_winner(user_choice, cpu_choice)
       # determine whether or not to increase the times played counter
       if result == 2:
           continue
       else:
           times_played += 1
       # find out who won and increase the winnings count
       if result == 0:
           user_wins += 1
       else:
           cpu_wins += 1
       # find out if this was the first try if either the user or computer want to extend to 2 outta 3
       if times_played == 1:
           if result == 1:
               user_choice = raw_input("do you want to try best 2 outta 3? (y/n): ").upper()
               while user_choice != "Y" and user_choice != "N":
                   user_choice = raw_input("enter [Y] - Yes or [N] - No: ").upper()
           else:
               print "cpu is deciding if it wants to try best 2 outta 3..."
               sleep(1)			# don't really need this, just adding for effect
               cpu_choice = randint(0, 1)
               if cpu_choice == 0:
                  cpu_choice = "N"
                  print "nope"
               else:
                  cpu_choice = "Y"
                  print "yep"
           if user_choice == "Y" or cpu_choice == "Y":
               continue
           else:
               return 1
       else:
          if user_wins > cpu_wins:
              print WIN_MESSAGE + " best 2 outta 3!"
              return 0
          elif cpu_wins > user_wins:
              print LOSS_MESSAGE + " best 2 outta 3!"
              return 1
          else:
              print "last try..."
     
# play the game
play_RPS()
