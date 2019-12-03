#!/usr/bin/python -tt
# Copyright 2010 Google Inc.
# Licensed under the Apache License, Version 2.0
# http://www.apache.org/licenses/LICENSE-2.0

# Google's Python Class
# http://code.google.com/edu/languages/google-python-class/

"""Mimic pyquick exercise -- optional extra exercise.
Google's Python Class

Read in the file specified on the command line.
Do a simple split() on whitespace to obtain all the words in the file.
Rather than read the file line by line, it's easier to read
it into one giant string and split it once.

Build a "mimic" dict that maps each word that appears in the file
to a list of all the words that immediately follow that word in the file.
The list of words can be be in any order and should include
duplicates. So for example the key "and" might have the list
["then", "best", "then", "after", ...] listing
all the words which came after "and" in the text.
We'll say that the empty string is what comes before
the first word in the file.

With the mimic dict, it's fairly easy to emit random
text that mimics the original. Print a word, then look
up what words might come next and pick one at random as
the next word.
Use the empty string as the first word to prime things.
If we ever get stuck with a word that is not in the dict,
go back to the empty string to keep things moving.

Note: the standard python module 'random' includes a
random.choice(list) method which picks a random element
from a non-empty list.

For fun, feed your program to itself as input.
Could work on getting it to put in linebreaks around 70
columns, so the output looks better.

"""

import random
import sys


def mimic_dict(filename):
  """Returns mimic dict mapping each word to list of words which follow it."""
  mimic_dict = {}
  input_file = open(filename, 'r')
  #all_words_in_file = input_file.split()
  all_words_in_file = input_file.read().split()
  prev_word = ''
  for word in all_words_in_file:
    if prev_word not in mimic_dict.keys():
       mimic_dict[prev_word] = []
    mimic_dict[prev_word].append(word)
    ## # from solutions
    ## if not prev in mimic_dict:
    ##   mimic_dict[prev] = [word]
    ## else:
    ##   mimic_dict[prev].append(word)
    prev_word = word
  input_file.close()
  ## for key in mimic_dict.keys():
  ##    print key, mimic_dict[key]
  return mimic_dict


def print_mimic(mimic_dict, word):
  """Given mimic dict and start word, prints 200 random words."""
  no_of_words_to_print = 200
  column_width = 70
  line_length = 0
  word_to_print = random.choice(mimic_dict[word])
  while no_of_words_to_print > 0:
    if line_length > column_width:
      print
      line_length = 0
    print word_to_print,
    line_length += len(word_to_print) + 1
    no_of_words_to_print -= 1
    if word_to_print in mimic_dict.keys():
      word_to_print = random.choice(mimic_dict[word_to_print])
    else:
      word_to_print = random.choice(mimic_dict[word])
  return


# Provided main(), calls mimic_dict() and mimic()
def main():
  if len(sys.argv) != 2:
    print 'usage: ./mimic.py file-to-read'
    sys.exit(1)

  dict = mimic_dict(sys.argv[1])
  print_mimic(dict, '')


if __name__ == '__main__':
  main()
