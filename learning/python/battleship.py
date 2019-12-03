#!/usr/bin/python
# 
# simple battleship program

from random import randint

board = []

print "Let's play Battleship!"
print
ocean_rows = int(raw_input("How many rows of ocean?: "))
ocean_cols = int(raw_input("How many cols of ocean?: "))

# create the game board
for row in range(ocean_rows):
    board.append(["O"] * ocean_cols)

# print out the board showing guesses
def print_board(board):
    print
    print "-" * (ocean_cols * 2 + 3)
    for row in board:
        #print " ".join(row)
        print "| " + " ".join(row) + " |"
    print "-" * (ocean_cols * 2 + 3)
    print

print_board(board)

def random_row(board):
    return randint(0, len(board) - 1)

def random_col(board):
    return randint(0, len(board[0]) - 1)

print "hiding the ship..."
ship_row = random_row(board)
ship_col = random_col(board)
# only print the following for debug
#debug#print ship_row
#debug#print ship_col

# create a loop to count how long it takes to find the ship
max_turns = (ocean_rows * ocean_cols) / 2
print "you have this many turns to guess: ", max_turns
for turn in range(max_turns):
    print "Turn", turn + 1
    guess_row = int(raw_input("    Guess Row: ")) - 1
    guess_col = int(raw_input("    Guess Col: ")) - 1

    if (guess_row < 0 or guess_row > ocean_rows - 1) or (guess_col < 0 or guess_col > ocean_cols - 1):
        print "WTF? That's not in the ocean. (Ocean size: %s X %s)" % (ocean_rows,ocean_cols)
    elif (board[guess_row][guess_col] == "X"):
        print "Duh - You guessed that one already."
    else:
        board[guess_row][guess_col] = "X"

    print_board(board)

    if guess_row == ship_row and guess_col == ship_col:
        print "==============="
        print "Congratulations! You sunk my battleship in %s turns!" % str(turn + 1)
        print "==============="
        board[guess_row][guess_col] = "*"
        print_board(board)
        break
    else:
        print "HA HA HA - You missed my battleship!"

    if turn + 1 == max_turns:
        board[ship_row][ship_col] = "="
        print "here's where the ship was"
        print_board(board)
        print "+---------+"
        print "|Game Over|"
        print "+---------+"
