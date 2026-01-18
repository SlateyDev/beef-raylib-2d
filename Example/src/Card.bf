using System;
using RaylibBeef;

namespace Example
{
    delegate void CardProc();

    public enum CardKind {
        Attack,
        Skill,
        Power,
    }

    public struct CardDefinition {
        public String name;
        public String flavourText;
        public int cost;
        public CardKind kind;
        public Texture2D artwork;
        public CardProc proc;
    }

    public struct Card {
        public CardDefinition definition;
        public bool selected;
        public Vector2 position;
        public float rotation;
    }
}