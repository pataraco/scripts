#!/usr/bin/python

"""
DNA Analysis Program (more classes, methods and file i/o)

In this project, I'll use many of the concepts I've learned in order to do some DNA analysis for a crime investigation.

The scenario:

A spy deleted important files from a computer. There were a few witnesses at the scene of the crime,
but no one is sure who exactly the spy was. Three possible suspects were apprehended based on
surveillance video. Each suspect had a sample of DNA taken from them. The computer's keyboard
was also swabbed for DNA evidence and, luckily, one small DNA sample was successfully retrieved
from the computer's keyboard.

Given the three suspects' DNA and the sample DNA retreived from the keyboard, it's up to you
to figure out who the spy is!

The project should have methods for each of the following:

 1. Given a file, read in the DNA for each suspect and save it as a string
 2. Take a DNA string and split it into a list of codons
 3. Iterate through a suspect's codon list to see how many of their codons match the sample codons
 4. Pick the right suspect to continue the investigation on

"""

BLU = "\033[34m"   # blue color
GRN = "\033[32m"   # green color
RED = "\033[31m"   # red color
NRM = "\033[m"     # to make text normal

SAMPLE = ['GTA', 'GGG', 'CAC']	# Sample taken from keyboard
FILES = ["dna_sample_suspect_1.txt", "dna_sample_suspect_2.txt", "dna_sample_suspect_3.txt"]

def read_dna(dna_file):
    dna_data = ""
    with open(dna_file, "r") as f:
        for line in f.read():
            dna_data += line
    return dna_data

def dna_codons(dna):
    codons = []
    dna_len = len(dna)
    for i in range(0, dna_len, 3):
        if (i+3) < dna_len:
            codons.append(dna[i:i+3])
    return list(codons)

def match_dna(codons):
    matches = {}
    for codon in SAMPLE:
        matches[codon] = 0
    matches['Total'] = 0
    for codon in codons:
        if codon in SAMPLE:
            matches[codon] += 1
            matches['Total'] += 1
    return dict(matches)

#def is_criminal(dna_sample):

for f in FILES:
    dna = read_dna(f)
    print dna
    print "-------"
    codons = dna_codons(dna)
    print codons
    print "-------"
    print match_dna(codons)
    print "==============="

