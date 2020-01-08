package main

import (
	"os"
	"testing"
)

func TestNewDeck(t *testing.T) {
	expectedLen := 52
	expectedFirstCard := "Ace of Clubs"
	expectedLastCard := "King of Spades"
	d := newDeck()
	deckLen := len(d)
	if deckLen != expectedLen {
		// t.Error("Expected deck length of", expectedLen, "but got:", deckLen)
		t.Errorf("Expected deck length of %v, but got %v", expectedLen, deckLen)
	}
	deckFirstCard := d[0]
	if deckFirstCard != expectedFirstCard {
		t.Errorf("Expected first card '%s', but got '%s'", expectedFirstCard, deckFirstCard)
	}
	deckLastCard := d[deckLen-1]
	if deckLastCard != expectedLastCard {
		t.Errorf("Expected last card '%s', but got '%s'", expectedLastCard, deckLastCard)
	}
}

func TestSaveToFile(t *testing.T) {
	expectedFileSize := int64(792)
	testingFilename := ".decktesting"
	os.Remove(testingFilename)
	d := newDeck()
	d.saveToFile(testingFilename)
	fs, err := os.Stat(testingFilename)
	if err != nil {
		t.Errorf("Error: get testing file status: %v", err)
	}
	if expectedFileSize != fs.Size() {
		t.Errorf("Expected file size '%v', but got '%v'", expectedFileSize, fs.Size())
	}
	os.Remove(testingFilename)
}

func TestNewDeckFromFile(t *testing.T) {
	testingFilename := ".decktesting"
	expectedLen := 52
	os.Remove(testingFilename)
	testedDeck := newDeck()
	testedDeck.saveToFile(testingFilename)
	loadedDeck := newDeckFromFile(testingFilename)
	deckLen := len(loadedDeck)
	if deckLen != expectedLen {
		t.Errorf("Expected loaded deck length of %v, but got %v", expectedLen, deckLen)
	}
	os.Remove(testingFilename)
}
