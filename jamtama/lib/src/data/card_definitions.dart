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
//
// Cards are themed as historical melee weapons.
// Move patterns are unchanged — only names and IDs have been replaced.
// ---------------------------------------------------------------------------

/// Wide-arcing polearm — strikes forward-diagonals and both sides.
const halberd = CardDefinition(
  id: 'halberd',
  name: 'Halberd',
  moves: [
    CardMove(-1, 1), CardMove(1, 1), // front-left, front-right
    CardMove(-1, 0), CardMove(1, 0), // left, right
  ],
  stampColor: Colors.red,
);

/// Heavy flanged club — batters straight forward and to both sides.
const mace = CardDefinition(
  id: 'mace',
  name: 'Mace',
  moves: [
    CardMove(0, 1),                  // forward
    CardMove(-1, 0), CardMove(1, 0), // left, right
  ],
  stampColor: Colors.red,
);

/// Curved harvesting blade — hooks forward-diagonals and pulls back.
const sickle = CardDefinition(
  id: 'sickle',
  name: 'Sickle',
  moves: [
    CardMove(-1, 1), CardMove(1, 1), // front-left, front-right
    CardMove(0, -1),                 // backward
  ],
  stampColor: Colors.red,
);

/// Thrusting pole weapon — lunges forward, retreats diagonally.
const spear = CardDefinition(
  id: 'spear',
  name: 'Spear',
  moves: [
    CardMove(0, 1),                    // forward
    CardMove(-1, -1), CardMove(1, -1), // back-left, back-right
  ],
  stampColor: Colors.blue,
);

/// Cavalry curved blade — advances, cuts left, withdraws.
const saber = CardDefinition(
  id: 'saber',
  name: 'Saber',
  moves: [
    CardMove(0, 1),  // forward
    CardMove(-1, 0), // left
    CardMove(0, -1), // backward
  ],
  stampColor: Colors.red,
);

/// Double-edged straight sword — advances, cuts right, withdraws.
const longsword = CardDefinition(
  id: 'longsword',
  name: 'Longsword',
  moves: [
    CardMove(0, 1),  // forward
    CardMove(1, 0),  // right
    CardMove(0, -1), // backward
  ],
  stampColor: Colors.blue,
);

/// Chain weapon — sweeps left and forward-left, right and back-right.
const flail = CardDefinition(
  id: 'flail',
  name: 'Flail',
  moves: [
    CardMove(-1, 0), CardMove(-1, 1), // left, front-left
    CardMove(1, 0),  CardMove(1, -1), // right, back-right
  ],
  stampColor: Colors.blue,
);

/// Crushing two-handed hammer — right, forward-right, left, back-left.
const warhammer = CardDefinition(
  id: 'warhammer',
  name: 'War Hammer',
  moves: [
    CardMove(1, 0),  CardMove(1, 1),  // right, front-right
    CardMove(-1, 0), CardMove(-1, -1), // left, back-left
  ],
  stampColor: Colors.red,
);

/// Short blade — strikes all four diagonal squares.
const dagger = CardDefinition(
  id: 'dagger',
  name: 'Dagger',
  moves: [
    CardMove(-1, 1), CardMove(1, 1),   // front-left, front-right
    CardMove(-1, -1), CardMove(1, -1), // back-left, back-right
  ],
  stampColor: Colors.blue,
);

/// Long curved blade on a pole — hooks front-left, cuts right, back-left.
const scythe = CardDefinition(
  id: 'scythe',
  name: 'Scythe',
  moves: [
    CardMove(-1, 1), // front-left
    CardMove(1, 0),  // right
    CardMove(-1, -1), // back-left
  ],
  stampColor: Colors.blue,
);

/// Slender thrusting sword — pierces front-right, parries left, back-right.
const rapier = CardDefinition(
  id: 'rapier',
  name: 'Rapier',
  moves: [
    CardMove(1, 1),  // front-right
    CardMove(-1, 0), // left
    CardMove(1, -1), // back-right
  ],
  stampColor: Colors.red,
);

/// Every card available for the community pool.
const allCards = <CardDefinition>[
  halberd, mace, sickle, spear, saber,
  longsword, flail, warhammer, dagger, scythe, rapier,
];

/// ID → CardDefinition registry. Used to deserialize persisted deck data.
/// Add new cards here when the catalogue grows.
final cardRegistry = <String, CardDefinition>{
  for (final c in allCards) c.id: c,
};

const redDefaultDeck  = Deck(cards: [halberd, mace, saber, longsword, spear, sickle]);
const blueDefaultDeck = Deck(cards: [flail, warhammer, dagger, scythe, rapier, sickle]);
