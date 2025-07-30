using System;

namespace Example
{
    public struct Card
    {
        public String suit;
        public String rank;

        public this(String suit, String rank)
        {
            this.suit = suit;
            this.rank = rank;
        }
    }
}