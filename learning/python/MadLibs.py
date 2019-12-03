#!/bin/python

"""
This is a basic Mad Libs program - yahoo!
"""

#The template for the story
STORY = "This morning I woke up and felt %s because %s was going to finally %s over the big %s %s.\nOn the other side of the %s were many %ss protesting to keep %s in stores.\nThe crowd began to %s to the rythym of the %s, which made all of the %ss very %s.\n%s tried to %s into the sewers and found %s rats.\nNeeding help, %s quickly called %s.\n%s appeared and saved %s by flying to %s and dropping %s into a puddle of %s.\n%s then fell asleep and woke up in the year %s, in a world where %ss ruled the world.\n"

print "Welcome to the Mad Libs program! Let's have some fun!"
print
print "I'm going to ask for a bunch of words to fill in the blanks"

print
main_character = raw_input("First, please enter the main character's name: ")

print
print "Second, we need three adjectives..."
adj_1 = raw_input("enter adjective #1: ")
adj_2 = raw_input("enter adjective #2: ")
adj_3 = raw_input("enter adjective #3: ")

print
print "Next, we need three verbs..."
verb_1 = raw_input("enter verb #1: ")
verb_2 = raw_input("enter verb #2: ")
verb_3 = raw_input("enter verb #3: ")

print
print "Finally, we need four nouns..."
noun_1 = raw_input("enter noun #1: ")
noun_2 = raw_input("enter noun #2: ")
noun_3 = raw_input("enter noun #3: ")
noun_4 = raw_input("enter noun #4: ")

print
print "Now, let's get crazy..."
animal = raw_input("give me an animal: ")
food = raw_input("give me a food: ")
fruit = raw_input("give me a fruit: ")
number = raw_input("give me a number: ")
superhero = raw_input("give me a superhero: ")
country = raw_input("give me a country: ")
dessert = raw_input("give me a dessert: ")
year = raw_input("give me a year: ")

print
print STORY % (adj_1, main_character, verb_1, adj_2, noun_1, noun_2, animal, food, verb_2, noun_3, fruit, adj_3, main_character, verb_3, number, main_character, superhero, superhero, main_character, country, main_character, dessert, main_character, year, noun_4)

