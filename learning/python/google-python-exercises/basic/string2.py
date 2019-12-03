#!/usr/bin/python2.4 -tt
# Copyright 2010 Google Inc.
# Licensed under the Apache License, Version 2.0
# http://www.apache.org/licenses/LICENSE-2.0

# Google's Python Class
# http://code.google.com/edu/languages/google-python-class/

# Additional basic string exercises

# D. verbing
# Given a string, if its length is at least 3,
# add 'ing' to its end.
# Unless it already ends in 'ing', in which case
# add 'ly' instead.
# If the string length is less than 3, leave it unchanged.
# Return the resulting string.
def verbing(s):
  ## # my original answer
  ## if (len(s) < 3):
  ##   return s
  ## if (s[-3:] == "ing"):
  ##   return s + "ly"
  ## else:
  ##   return s + "ing"
  # another solution (modified from Google's solution)
  if (len(s) >= 3):
     if (s[-3:] == "ing"):
       s += "ly"
     else:
       s += "ing"
  return s


# E. not_bad
# Given a string, find the first appearance of the
# substring 'not' and 'bad'. If the 'bad' follows
# the 'not', replace the whole 'not'...'bad' substring
# with 'good'.
# Return the resulting string.
# So 'This dinner is not that bad!' yields:
# This dinner is good!
def not_bad(s):
  ## # my original answer
  ## not_loc = s.find('not')
  ## bad_loc = s.find('bad')
  ## if (not_loc != -1 and bad_loc != -1):
  ##   if (not_loc < bad_loc):
  ##     s = s.replace(s[not_loc:bad_loc+3],'good')
  ## return s
  # another solution (modified from Google's solution)
  not_loc = s.find('not')
  bad_loc = s.find('bad')
  if (not_loc != -1 and bad_loc != -1 and not_loc < bad_loc):
    #s = s[:not_loc] + 'good' + s[bad_loc+3:]	# google's
    s = s.replace(s[not_loc:bad_loc+3],'good')	# mine
  return s


# F. front_back
# Consider dividing a string into two halves.
# If the length is even, the front and back halves are the same length.
# If the length is odd, we'll say that the extra char goes in the front half.
# e.g. 'abcde', the front half is 'abc', the back half 'de'.
# Given 2 strings, a and b, return a string of the form
#  a-front + b-front + a-back + b-back
def front_back(a, b):
  # my original answer
  a_l = len(a)
  if (a_l % 2 == 0):
    a_h = a_l/2
  else:
    a_h = (a_l-1)/2+1
  a_f = a[0:a_h]
  #a_b = a[-(a_l-a_h):]	# original
  a_b = a[a_h:]		# modified
  b_l = len(b)
  if (b_l % 2 == 0):
    b_h = b_l/2
  else:
    b_h = b_l/2+1
  b_f = b[0:b_h]
  #b_b = b[-(b_l-b_h):]	# original
  b_b = b[b_h:]		# modified
  return a_f + b_f + a_b + b_b
  ## # Google's solution
  ## # Figure out the middle position of each string.
  ## a_middle = len(a) / 2
  ## b_middle = len(b) / 2
  ## if len(a) % 2 == 1:  # add 1 if length is odd
  ##   a_middle = a_middle + 1
  ## if len(b) % 2 == 1:
  ##   b_middle = b_middle + 1
  ## return a[:a_middle] + b[:b_middle] + a[a_middle:] + b[b_middle:]


# Simple provided test() function used in main() to print
# what each function returns vs. what it's supposed to return.
def test(got, expected):
  if got == expected:
    prefix = ' OK '
  else:
    prefix = '  X '
  print '%s got: %s expected: %s' % (prefix, repr(got), repr(expected))


# main() calls the above functions with interesting inputs,
# using the above test() to check if the result is correct or not.
def main():
  print 'verbing'
  test(verbing('hail'), 'hailing')
  test(verbing('swiming'), 'swimingly')
  test(verbing('do'), 'do')

  print
  print 'not_bad'
  test(not_bad('This movie is not so bad'), 'This movie is good')
  test(not_bad('This dinner is not that bad!'), 'This dinner is good!')
  test(not_bad('This tea is not hot'), 'This tea is not hot')
  test(not_bad("It's bad yet not"), "It's bad yet not")
  test(not_bad('This not bad dinner is hot!'), 'This good dinner is hot!')

  print
  print 'front_back'
  test(front_back('abcd', 'xy'), 'abxcdy')
  test(front_back('abcde', 'xyz'), 'abcxydez')
  test(front_back('Kitten', 'Donut'), 'KitDontenut')

if __name__ == '__main__':
  main()
