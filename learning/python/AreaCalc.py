#!/bin/python

"""
this is a program to calculate the areas of shapes!
"""

from math import pi
from time import sleep
from datetime import datetime

hint = "Don't forget to include the correct units!\nExiting..."
now = datetime.now()

print "Hello and welcome to the Area Calculator!"
print
print "Current date (DD/MM/YYYY)/time: %s-%s-%s %s:%s" % (now.day, now.month, now.year, now.hour, now.minute)

print
print "warming up..."
sleep(1)

option = raw_input("enter 'C' for 'Circle' or 'T' for 'Triangle': ").upper()

while option != "C" and option != "T":
    print "wrong option, please enter either 'C' or 'T'"
    option = raw_input("enter 'C' for 'Circle' or 'T' for 'Triangle': ").upper()
if option == "C":
    print "ok, working with a circle..."
    radius = float(raw_input("please enter the size of the radius: "))
    print "calculating..."
    area = pi * radius**2
    sleep(1)
    print "the area of a circle with radius %.2f is %.2f\n%s" % (radius, area, hint)
elif option == "T":
    print "ok, working with a triangle..."
    base = float(raw_input("please enter the size of the base: "))
    height = float(raw_input("please enter the size of the height: "))
    print "calculating..."
    area = (0.5) * base * height
    sleep(1)
    print "the area of a triangle with base %.2f and height %.2f is %.2f\n%s" % (base, height , area, hint)
else:
    print "wrong option, please enter either 'C' or 'T'"
