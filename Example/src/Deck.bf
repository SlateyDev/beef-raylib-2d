using System;
using System.Collections;

namespace Example
{
    public class Deck {
        private List<Card> cards = new List<Card>();
        private Random random = new Random();

        public this() {
        }

        public void AddCard(Card item) {
            cards.Add(item);
        }

        public void Shuffle() {
            int n = cards.Count;
            while (n > 1) {
                n--;
                int k = random.Next(0, n + 1);
                if (k == n) continue;
                Card temp = cards[k];
                cards[k] = cards[n];
                cards[n] = temp;
            }
        }

        public Result<Card> DrawCard() {
            if (cards.Count == 0) return .Err;

            Card card = cards[cards.Count - 1];
            cards.RemoveAt(cards.Count - 1);
            return .Ok(card);
        }

        public ~this() {
            delete cards;
            delete random;
        }
    }
}