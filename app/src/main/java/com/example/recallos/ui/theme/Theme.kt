package com.example.recallos.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

// ─── Apricot Soft-Touch Light Color Scheme ───────────────────────────────────
private val ApricotLightColorScheme = lightColorScheme(
    primary              = Primary,
    onPrimary            = OnPrimary,
    primaryContainer     = PrimaryContainer,
    onPrimaryContainer   = OnPrimaryContainer,
    inversePrimary       = InversePrimary,

    secondary            = Secondary,
    onSecondary          = OnSecondary,
    secondaryContainer   = SecondaryContainer,
    onSecondaryContainer = OnSecondaryContainer,

    tertiary             = Tertiary,
    onTertiary           = OnTertiary,
    tertiaryContainer    = TertiaryContainer,
    onTertiaryContainer  = OnTertiaryContainer,

    error                = Error,
    onError              = OnError,
    errorContainer       = ErrorContainer,
    onErrorContainer     = OnErrorContainer,

    background           = Background,
    onBackground         = OnBackground,
    surface              = Surface,
    onSurface            = OnSurface,
    surfaceVariant       = SurfaceVariantColor,
    onSurfaceVariant     = OnSurfaceVariant,
    surfaceTint          = Primary,
    inverseSurface       = InverseSurface,
    inverseOnSurface     = InverseOnSurface,
    outline              = Outline,
    outlineVariant       = OutlineVariant,
)

// ─── Dark theme keeps the same brand feeling, just dimmed ────────────────────
private val ApricotDarkColorScheme = darkColorScheme(
    primary              = InversePrimary,
    onPrimary            = OnPrimaryFixed,
    primaryContainer     = OnPrimaryFixedVar,
    onPrimaryContainer   = PrimaryFixed,

    secondary            = SecondaryFixedDim,
    onSecondary          = OnSecondaryFixed,
    secondaryContainer   = OnSecondaryFixedVar,
    onSecondaryContainer = SecondaryFixed,

    tertiary             = TertiaryFixedDim,
    onTertiary           = OnTertiaryFixed,
    tertiaryContainer    = OnTertiaryFixedVar,
    onTertiaryContainer  = TertiaryFixed,

    error                = Error,
    onError              = OnError,
    errorContainer       = ErrorContainer,
    onErrorContainer     = OnErrorContainer,

    background           = InverseSurface,
    onBackground         = InverseOnSurface,
    surface              = InverseSurface,
    onSurface            = InverseOnSurface,
    surfaceVariant       = OnSurfaceVariant,
    onSurfaceVariant     = OutlineVariant,
    inverseSurface       = Surface,
    inverseOnSurface     = OnSurface,
    outline              = Outline,
    outlineVariant       = OnSurfaceVariant,
)

@Composable
fun RecallOSTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    // Dynamic color intentionally disabled — brand identity must stay consistent
    val colorScheme = if (darkTheme) ApricotDarkColorScheme else ApricotLightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography  = Typography,
        shapes      = ApricotShapes,
        content     = content
    )
}
