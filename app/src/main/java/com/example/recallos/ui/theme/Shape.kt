package com.example.recallos.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

/**
 * Apricot Soft-Touch shape scale.
 *
 *  sm  → 0.25rem = 4dp   (chips, tags, badges)
 *  md  → 0.75rem = 12dp  (buttons, inputs, small cards)
 *  lg  → 1.0rem  = 16dp  (todo rows, list items)
 *  xl  → 1.5rem  = 24dp  (cards, modals — the signature radius)
 *  full → 9999px         (pills, FABs)
 */
val ApricotShapes = Shapes(
    extraSmall = RoundedCornerShape(4.dp),
    small      = RoundedCornerShape(8.dp),
    medium     = RoundedCornerShape(12.dp),
    large      = RoundedCornerShape(16.dp),
    extraLarge = RoundedCornerShape(24.dp),
)

// Convenience shorthand for use across the UI
val RadiusSm   = RoundedCornerShape(4.dp)
val RadiusMd   = RoundedCornerShape(8.dp)
val RadiusLg   = RoundedCornerShape(12.dp)
val RadiusXl   = RoundedCornerShape(16.dp)
val RadiusCard = RoundedCornerShape(24.dp)
val RadiusFull = RoundedCornerShape(50)

// Top-only 28dp — used for ModalBottomSheet so the pill matches the card spec
val RadiusSheetTop = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp)

// Top-only 24dp — used to clip the image inside a card so it follows the card's top radius
val RadiusCardTop  = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)
