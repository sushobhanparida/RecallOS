package com.example.recallos.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.googlefonts.Font
import androidx.compose.ui.text.googlefonts.GoogleFont
import androidx.compose.ui.unit.sp
import com.example.recallos.R

// ─── Plus Jakarta Sans via Google Fonts ──────────────────────────────────────
private val fontProvider = GoogleFont.Provider(
    providerAuthority = "com.google.android.gms.fonts",
    providerPackage   = "com.google.android.gms",
    certificates      = R.array.com_google_android_gms_fonts_certs
)

private val plusJakartaSans = GoogleFont("Plus Jakarta Sans")

val PlusJakartaSansFontFamily = FontFamily(
    Font(googleFont = plusJakartaSans, fontProvider = fontProvider, weight = FontWeight.Normal),
    Font(googleFont = plusJakartaSans, fontProvider = fontProvider, weight = FontWeight.Medium),
    Font(googleFont = plusJakartaSans, fontProvider = fontProvider, weight = FontWeight.SemiBold),
    Font(googleFont = plusJakartaSans, fontProvider = fontProvider, weight = FontWeight.Bold),
    Font(googleFont = plusJakartaSans, fontProvider = fontProvider, weight = FontWeight.ExtraBold),
)

// ─── Apricot Soft-Touch Type Scale ───────────────────────────────────────────
val Typography = Typography(
    // headline-lg  40px / 700 / -0.02em
    displayLarge = TextStyle(
        fontFamily    = PlusJakartaSansFontFamily,
        fontWeight    = FontWeight.Bold,
        fontSize      = 40.sp,
        lineHeight    = 48.sp,
        letterSpacing = (-0.8).sp
    ),
    // headline-md  28px / 600 / -0.01em
    headlineLarge = TextStyle(
        fontFamily    = PlusJakartaSansFontFamily,
        fontWeight    = FontWeight.SemiBold,
        fontSize      = 28.sp,
        lineHeight    = 36.sp,
        letterSpacing = (-0.28).sp
    ),
    // headline-sm  20px / 600 / 0
    headlineMedium = TextStyle(
        fontFamily    = PlusJakartaSansFontFamily,
        fontWeight    = FontWeight.SemiBold,
        fontSize      = 20.sp,
        lineHeight    = 28.sp,
        letterSpacing = 0.sp
    ),
    headlineSmall = TextStyle(
        fontFamily    = PlusJakartaSansFontFamily,
        fontWeight    = FontWeight.SemiBold,
        fontSize      = 18.sp,
        lineHeight    = 25.sp,
        letterSpacing = 0.sp
    ),
    titleLarge = TextStyle(
        fontFamily    = PlusJakartaSansFontFamily,
        fontWeight    = FontWeight.SemiBold,
        fontSize      = 20.sp,
        lineHeight    = 28.sp,
        letterSpacing = 0.sp
    ),
    titleMedium = TextStyle(
        fontFamily    = PlusJakartaSansFontFamily,
        fontWeight    = FontWeight.SemiBold,
        fontSize      = 16.sp,
        lineHeight    = 24.sp,
        letterSpacing = 0.15.sp
    ),
    titleSmall = TextStyle(
        fontFamily    = PlusJakartaSansFontFamily,
        fontWeight    = FontWeight.Medium,
        fontSize      = 14.sp,
        lineHeight    = 20.sp,
        letterSpacing = 0.1.sp
    ),
    // body-lg  18px / 400 / 0  (line-height 1.6)
    bodyLarge = TextStyle(
        fontFamily    = PlusJakartaSansFontFamily,
        fontWeight    = FontWeight.Normal,
        fontSize      = 18.sp,
        lineHeight    = 28.sp,
        letterSpacing = 0.sp
    ),
    // body-md  16px / 400 / 0  (line-height 1.6)
    bodyMedium = TextStyle(
        fontFamily    = PlusJakartaSansFontFamily,
        fontWeight    = FontWeight.Normal,
        fontSize      = 16.sp,
        lineHeight    = 25.sp,
        letterSpacing = 0.sp
    ),
    bodySmall = TextStyle(
        fontFamily    = PlusJakartaSansFontFamily,
        fontWeight    = FontWeight.Normal,
        fontSize      = 13.sp,
        lineHeight    = 20.sp,
        letterSpacing = 0.sp
    ),
    // label-md  14px / 600 / 0.02em
    labelLarge = TextStyle(
        fontFamily    = PlusJakartaSansFontFamily,
        fontWeight    = FontWeight.SemiBold,
        fontSize      = 14.sp,
        lineHeight    = 14.sp,
        letterSpacing = 0.28.sp
    ),
    // label-sm  12px / 500 / 0.05em
    labelMedium = TextStyle(
        fontFamily    = PlusJakartaSansFontFamily,
        fontWeight    = FontWeight.Medium,
        fontSize      = 12.sp,
        lineHeight    = 12.sp,
        letterSpacing = 0.6.sp
    ),
    labelSmall = TextStyle(
        fontFamily    = PlusJakartaSansFontFamily,
        fontWeight    = FontWeight.Medium,
        fontSize      = 11.sp,
        lineHeight    = 11.sp,
        letterSpacing = 0.55.sp
    ),
)
