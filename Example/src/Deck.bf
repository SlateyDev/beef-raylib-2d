using System;
using System.Collections;

namespace Example
{
    public class Deck
    {
        private List<Card> cards = new List<Card>();
        private Random random = new Random();

        String[?] suits = .("Hearts", "Diamonds", "Clubs", "Spades");
        String[?] ranks = .("Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King");

        public this()
        {
            for (let suit in suits)
            {
                for (let rank in ranks)
                {
                    cards.Add(Card(suit, rank));
                }
            }
        }

        public void Shuffle()
        {
            int n = cards.Count;
            while (n > 1)
            {
                n--;
                int k = random.Next(0, n + 1);
                Card temp = cards[k];
                cards[k] = cards[n];
                cards[n] = temp;
            }
        }

        public Card DrawCard()
        {
            if (cards.Count == 0)
                return Card("", ""); // Empty card if deck is empty

            Card card = cards[cards.Count - 1];
            cards.RemoveAt(cards.Count - 1);
            return card;
        }

        public ~this()
        {
            delete cards;
            delete random;
        }
    }
}