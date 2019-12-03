#!/usr/bin/python

"""
Basic Bank Account program

(working with classes)

In this project, I'll create a Python class that can be used to create and manipulate
a personal bank account.

The bank account class I'll create should have methods for each of the following:

 1. Accepting deposits
 2. Allowing withdrawals
 3. Showing the balance
 4. Showing the details of the account

"""

BLU = "\033[34m"   # blue color
GRN = "\033[32m"   # green color
RED = "\033[31m"   # red color
NRM = "\033[m"     # to make text normal

class BankAccount(object):
    # TODO - change this to read the balance from a file
    balance = 0

    def __init__(self, name):
        self.name = name
        
    def __repr__(self):
        if self.balance < 0:
            return "Owner: (%s)   Balance: %s$%.2f%s" % (self.name, RED, self.balance, NRM)
        else:
            return "Owner: (%s)   Balance: %s$%.2f%s" % (self.name, GRN, self.balance, NRM)

    def show_balance(self):
        if self.balance < 0:
            print "Owner: (%s)   Balance: %s$%.2f%s" % (self.name, RED, self.balance, NRM)
        else:
            print "Owner: (%s)   Balance: %s$%.2f%s" % (self.name, GRN, self.balance, NRM)

    def deposit(self, amount):
        if amount <= 0:
            print "%sNot depositing a non-positive value%s" % (RED, NRM)
            return 2
        else:
            self.balance += amount
            print "%.2f %sdeposited%s into account: %s" % (amount, GRN, NRM, self.name)
            print "here is the %snew balance%s:" % (BLU, NRM)
            self.show_balance()

    def withdraw(self, amount):
        if amount <= 0:
            print "%sNot withdrawing a non-positive value%s" % (RED, NRM)
            return 2
        if amount > self.balance:
            print "%sNot enough funds available!%s" % (RED, NRM)
            print "here is the %sbalance%s:" % (BLU, NRM)
            self.show_balance()
            return 1
        else:
            self.balance -= amount
            print "%swithdrew%s %.2f from account: %s" % (GRN, NRM, amount, self.name)
            print "here is the %snew balance%s:" % (BLU, NRM)
            self.show_balance()

def menu():
    print
    print "Welcome to Raco Banking!"
    print
    while True:
       print "What would you like to do?"
       print
       print "    C. Create an account"
       print "    D. Deposit money"
       print "    W. Withdrawal money"
       print "    P. Print balance"
       print "    Q. Quit"
       print
       option = raw_input("  Please enter your choice: ").upper()
       while option not in ('C', 'D', 'W', 'P', 'Q'):
           print "%sBad Choice!%s" % (RED,NRM)
           option = raw_input(" Please enter one of these choices (C, D, W, P, Q): ").upper()
       if option == 'C':
           name = raw_input(" Please enter the name on the account: ")
           account = BankAccount(name)
       elif option == 'D':
           amount = float(raw_input(" Please enter the amount to deposit: "))
           account.deposit(amount)
       elif option == 'W':
           amount = float(raw_input(" Please enter the amount to withdraw: "))
           account.withdraw(amount)
       elif option == 'P':
           print "here is the %sbalance%s:" % (BLU, NRM)
           account.show_balance()
       elif option == 'Q':
           print "thanks - have a nice day!"
           return 1
       else:
           print "Hmmm... %sSomething's seriously wrong%s! Shouldn't end up here..." % (RED,NRM)
           return 2

menu()
