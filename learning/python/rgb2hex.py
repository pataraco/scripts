#!/usr/bin/python

"""
RGB <-> Hex Calculator

In this project, we'll use Bitwise operators to build a calculator that can convert RGB values to Hexadecimal (hex) values, and vice-versa.

We'll add three methods to the project:

  I. A method to convert RGB to Hex
 II. A method to convert Hex to RGB
III. A method that starts the prompt cycle

The program should do the following:

  1. Prompt the user for the type of conversion they want
  2. Ask the user to input the RGB or Hex value
  3. Use Bitwise operators and shifting in order to convert the value
  4. Print the converted value to the user

References:

  https://en.wikipedia.org/wiki/RGB_color_model
  https://en.wikipedia.org/wiki/Hexadecimal

"""

BLU = "\033[34m"   # blue color
GRN = "\033[32m"   # green color
RED = "\033[31m"   # red color
NRM = "\033[m"     # to make text normal

def rgb_to_hex():
    invalid_msg = "you entered an invalid RGB value"
    print "Converting from RGB to HEX"
    red = int(raw_input("Please enter a value (0-255) for " + RED + "RED" + NRM + ": "))
    while red < 0 or red > 255:
        print invalid_msg
        red = int(raw_input("Please enter a value (0-255) for " + RED + "RED" + NRM + ": "))
    green = int(raw_input("Please enter a value (0-255) for " + GRN + "GREEN" + NRM + ": "))
    while green < 0 or green > 255:
        print invalid_msg
        green = int(raw_input("Please enter a value (0-255) for " + GRN + "GREEN" + NRM + ": "))
    blue = int(raw_input("Please enter a value (0-255) for " + BLU + "BLUE" + NRM + ": "))
    while blue < 0 or blue > 255:
        print invalid_msg
        blue = int(raw_input("Please enter a value (0-255) for " + BLU + "BLUE" + NRM + ": "))
    rgb_val = (red << 16) + (green << 8) + blue
    hex_val = hex(rgb_val).upper()[2:]
    print "RGB (%d, %d, %d) = HEX (%s)" % (red,green,blue,hex_val)
    return hex_val

def hex_to_rgb():
    invalid_msg = "you entered an invalid HEX value"
    print "Converting from HEX to RGB "
    hex_val = int(raw_input("Please enter a hex value (0-FFFFFF): "),16)
    while hex_val < 0 or hex_val > 16777215:
        print invalid_msg
        hex_val = int(raw_input("Please enter a hex value (0-FFFFFF): "),16)
    orig_hex_val = hex_val
    two_hex_digits = 2**8
    blue = hex_val % two_hex_digits
    hex_val >>= 8
    green = hex_val % two_hex_digits
    hex_val >>= 8
    red = hex_val % two_hex_digits
    print "HEX (%x) = RGB (%d, %d, %d)" % (orig_hex_val,red,green,blue)
    return (red, green, blue)

def convert():
    while True:
        print "What would you like to do?"
        print
        print "    1. Convert from RGB to HEX"
        print "    2. Convert from HEX to RGB"
        print "    Q. Quit"
        print
        option = raw_input("  Please enter your choice (1, 2, or Q): ").upper()
        while option not in ('1', '2', 'Q'):
            print "%sBad Choice!%s" % (RED,NRM)
            user_choice = raw_input("  Please enter one of these choices (1, 2, Q): ").upper()
        if option == '1':
            rgb_to_hex()
        elif option == '2':
            hex_to_rgb()
        elif option == 'Q':
            print "thanks - have a nice day!"
            return 0
        else:
            print "Hmmm... %sSomething's seriously wrong%s! Shouldn't end up here..." % (RED,NRM)
            return 2

convert()
