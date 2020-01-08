package main

import "fmt"

func main() {
	cards := newDeck()
	fmt.Println("all cards")
	cards.print()

	hand, remainingCards := deal(cards, 5)
	fmt.Println("dealt cards")
	hand.print()

	fmt.Println("remaining cards")
	remainingCards.print()

	fmt.Println("cards as one string")
	fmt.Println(cards.toString())

	filename := "bicycle.txt"
	cards.saveToFile(filename)
	fmt.Println("saved to file:", filename)

	// filename = "notfound.txt"
	moreCards := newDeckFromFile(filename)
	fmt.Println("new from file:", filename)
	moreCards.print()

	cards.shuffle()
	cards.shuffle()
	fmt.Println("shuffled cards")
	cards.print()
}
