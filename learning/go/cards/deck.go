package main

import (
	"fmt"
	"io/ioutil"
	"math/rand"
	"os"
	"strings"
	"time"
)

// Create a new type of 'deck' - which is a slice of string
type deck []string

// Create a new deck of cards
func newDeck() deck {
	cards := deck{}
	cardSuits := []string{"Clubs", "Diamonds", "Hearts", "Spades"}
	cardValues := []string{
		"Ace",
		"Two",
		"Three",
		"Four",
		"Five",
		"Six",
		"Seven",
		"Eight",
		"Nine",
		"Ten",
		"Jack",
		"Queen",
		"King"}
	for _, suit := range cardSuits {
		for _, value := range cardValues {
			cards = append(cards, value+" of "+suit)
		}
	}
	return cards
}

// Print out the deck of cards
func (d deck) print() {
	for i, card := range d {
		fmt.Println(i, card)
	}
}

// Deal out a hand of cards (and the remaining)
func deal(d deck, handSize int) (deck, deck) {
	return d[:handSize], d[handSize:]
}

// Shuffle deck
func (d deck) shuffle() {
	source := rand.NewSource(time.Now().UnixNano())
	r := rand.New(source)
	for i := range d {
		newPosition := r.Intn(len(d) - 1)
		d[i], d[newPosition] = d[newPosition], d[i]
	}
}

// Convert deck to string
func (d deck) toString() string {
	return strings.Join([]string(d), ",")
}

// Save deck to a file
func (d deck) saveToFile(filename string) error {
	return ioutil.WriteFile(filename, []byte(d.toString()), 0666)
}

// Save deck to a file
func newDeckFromFile(filename string) deck {
	bs, err := ioutil.ReadFile(filename)
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	s := strings.Split(string(bs), ",")
	return deck(s)
}
