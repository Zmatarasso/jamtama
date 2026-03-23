import 'package:flutter/material.dart';

import '../models/card.dart';
import '../models/deck.dart';

// ---------------------------------------------------------------------------
// Card definitions — moves are from the CURRENT player's perspective:
//   dy: +1 = forward (toward opponent)   dy: -1 = backward
//   dx: +1 = right                        dx: -1 = left
//
// Red is at row 0 and moves toward row 4 (forward = +row).
// Blue is at row 4 and moves toward row 0 (forward = -row).
// The provider flips both dx/dy for Blue when computing valid squares.
// ---------------------------------------------------------------------------

const elephant = CardDefinition(
  id: 'elephant',
  name: 'Elephant',
  moves: [
    CardMove(-1, 1), CardMove(1, 1), // left-fwd, right-fwd
    CardMove(-1, 0), CardMove(1, 0), // left, right
  ],
  stampColor: Colors.red,
);

const boar = CardDefinition(
  id: 'boar',
  name: 'Boar',
  moves: [
    CardMove(0, 1), // forward
    CardMove(-1, 0), CardMove(1, 0), // left, right
  ],
  stampColor: Colors.red,
);

const mantis = CardDefinition(
  id: 'mantis',
  name: 'Mantis',
  moves: [
    CardMove(-1, 1), CardMove(1, 1), // left-fwd, right-fwd
    CardMove(0, -1), // backward
  ],
  stampColor: Colors.red,
);

const crane = CardDefinition(
  id: 'crane',
  name: 'Crane',
  moves: [
    CardMove(0, 1), // forward
    CardMove(-1, -1), CardMove(1, -1), // left-back, right-back
  ],
  stampColor: Colors.blue,
);

const horse = CardDefinition(
  id: 'horse',
  name: 'Horse',
  moves: [
    CardMove(0, 1), // forward
    CardMove(-1, 0), // left
    CardMove(0, -1), // backward
  ],
  stampColor: Colors.red,
);

const ox = CardDefinition(
  id: 'ox',
  name: 'Ox',
  moves: [
    CardMove(0, 1), // forward
    CardMove(1, 0), // right
    CardMove(0, -1), // backward
  ],
  stampColor: Colors.blue,
);

const goose = CardDefinition(
  id: 'goose',
  name: 'Goose',
  moves: [
    CardMove(-1, 0), CardMove(-1, 1), // left, left-fwd
    CardMove(1, 0), CardMove(1, -1), // right, right-back
  ],
  stampColor: Colors.blue,
);

const rooster = CardDefinition(
  id: 'rooster',
  name: 'Rooster',
  moves: [
    CardMove(1, 0), CardMove(1, 1), // right, right-fwd
    CardMove(-1, 0), CardMove(-1, -1), // left, left-back
  ],
  stampColor: Colors.red,
);

const monkey = CardDefinition(
  id: 'monkey',
  name: 'Monkey',
  moves: [
    CardMove(-1, 1), CardMove(1, 1), // diag-fwd
    CardMove(-1, -1), CardMove(1, -1), // diag-back
  ],
  stampColor: Colors.blue,
);

const eel = CardDefinition(
  id: 'eel',
  name: 'Eel',
  moves: [
    CardMove(-1, 1), // left-fwd
    CardMove(1, 0), // right
    CardMove(-1, -1), // left-back
  ],
  stampColor: Colors.blue,
);

const cobra = CardDefinition(
  id: 'cobra',
  name: 'Cobra',
  moves: [
    CardMove(1, 1), // right-fwd
    CardMove(-1, 0), // left
    CardMove(1, -1), // right-back
  ],
  stampColor: Colors.red,
);

/// Every card available for the community pool.
const allCards = <CardDefinition>[
  elephant, boar, mantis, crane, horse,
  ox, goose, rooster, monkey, eel, cobra,
];

const redDefaultDeck = Deck(cards: [elephant, boar, horse, ox, crane, mantis]);
const blueDefaultDeck = Deck(cards: [goose, rooster, monkey, eel, cobra, mantis]);
