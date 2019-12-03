#!/usr/bin/python

"""

Simple Calendar

The program should do the following:

1. Print a welcome message to the user
2. Prompt the user to view, add, update, or delete an event on the calendar
3. Depending on the user's input: view, add, update, or delete an event on the calendar
4. The program should never terminate unless the user decides to exit

"""

from time import sleep, strftime
import os

GRN = "\033[32m"   # green color
RED = "\033[31m"   # red color
NRM = "\033[m"     # to make text normal

try:
    USER=os.environ['USERNAME']
except KeyError:
    try:
        USER=os.environ['USER']
    except KeyError:
        USER = raw_input("Please enter your name: ")

# going to use a dictionary for the calendar events
calendar = {}

def welcome():
    print "Hello " + USER + "!"
    print
    print "Welcome to Raco Calendar!"
    print
    print "Warming up..."
    sleep(1)			# don't really need this, just adding for effect
    print strftime("Date: %d-%b-%Y    Time: %H:%M:%S")
    
def get_valid_date():
    date = raw_input("What date? (MM/DD/YYYY): ")
    while len(date) != 10:
        print "%sinvalid date%s" % (RED,NRM)
        date = raw_input("Please enter a valid date (MM/DD/YYYY): ")
    while int(date[6:]) < int(strftime('%Y'))-1:
        print "year you're trying to specify: %d" % int(date[6:])
        print "current year: %d and 'current year - 1': %d" % (int(strftime('%Y')),int(strftime('%Y'))-1)
        print "%sCan't access events that far in the past%s, stay within 1 year from now" % (RED,NRM)
        date = raw_input("Please enter another date (MM/DD/YYYY): ")
    return date

def start_calendar():
    welcome()

    start = True
    while start:
        print
        print "What would you like to do?"
        print
        print "    [%sA%s]-Add" % (GRN,NRM)
        print "    [%sD%s]-Delete" % (GRN,NRM)
        print "    [%sU%s]-Update" % (GRN,NRM)
        print "    [%sV%s]-View" % (GRN,NRM)
        print "    [%sQ%s]-Quit" % (GRN,NRM)
        print
        user_choice = raw_input("  Please enter your choice (A, D, U, V, Q): ").upper()
        while user_choice not in ('A', 'D', 'U', 'V', 'Q'):
            print "%sBad Choice!%s" % (RED,NRM)
            user_choice = raw_input("  Please enter one of these choices (A, D, U, V, Q): ").upper()
        print
        if user_choice == 'A':
            print "Adding to calendar..."
            date = get_valid_date()
            event = raw_input("Enter the event: ")
            calendar[date] = event
            print "%sAdd completed%s, here's the new calendar:" % (GRN,NRM)
            print "-------"
            print calendar
        elif user_choice == 'D':
            print "%sDeleting%s from calendar..." % (RED,NRM)
            if len(calendar.keys()) < 1:
                print "there are %sno calendar events%s" % (RED,NRM)
            else:
                event = raw_input("What event do you want to delete: ")
                found = False
                for date in calendar.keys():
                    if calendar[date] == event:
                        del(calendar[date])
                        print "%sEvent deleted%s from date: %s" % (GRN,NRM,date)
                        found = True
                if not found:
                    print "%sCould not find%s that event" % (RED,NRM)
                if len(calendar.keys()) < 1:
                    print "there are %sno calendar events%s now" % (RED,NRM)
                else:
                    print "-------"
                    print calendar
        elif user_choice == 'U':
            print "Updating calendar event..."
            date = get_valid_date()
            update = raw_input("Enter the update: ")
            calendar[date] = update
            print "Update %scompleted%s, here's the new calendar:" % (GRN,NRM)
            print "-------"
            print calendar
        elif user_choice == 'V':
            print "Viewing calendar..."
            if len(calendar.keys()) < 1:
                print "there are %sno calendar events%s" % (RED,NRM)
            else:
                print "-------"
                print calendar
        elif user_choice == 'Q':
            print "Quiting calendar..."
            start = False
        else:
            print "Hmmm... %sSomething's seriously wrong%s! Shouldn't end up here..." % (RED,NRM)
            return 1
        
start_calendar()
