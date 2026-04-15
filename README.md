# RecallOS

RecallOS is your personal visual memory assistant for Android. It automatically captures, processes, and organizes your screenshots, making it easy to find that "one thing" you saw a few days ago but forgot to save.

## 🚀 What it does

RecallOS works silently in the background to turn your messy screenshot folder into a searchable, categorized database of information.

### 🔍 Searchable Memory
Never scroll through thousands of images again. RecallOS uses **ML Kit Text Recognition (OCR)** to index all the text within your screenshots. Simply type a keyword, and RecallOS will find the relevant image instantly.

### 🏷️ Intelligent Auto-Tagging
The app automatically categorizes your screenshots based on their content:
*   **Shopping:** Detects currency symbols like ₹ and $.
*   **Links:** Identifies URLs for websites you wanted to visit later.
*   **Events:** Recognizes dates and years to help you find appointment info or tickets.
*   **Reading:** Tags long-form text as "Read" for later consumption.

### 📸 Seamless Integration
*   **Background Scanning:** Automatically detects when you take a new screenshot.
*   **Instant Action:** Shows a notification with an "Add to RecallOS" button as soon as a screenshot is captured.
*   **Pull-to-Refresh:** Manually trigger a scan of your entire screenshots folder at any time.

## 🛠️ Built With
*   **Kotlin & Jetpack Compose:** For a modern, fluid user interface.
*   **Room Database:** Secure local storage for your screenshot data and extracted text.
*   **WorkManager:** Efficient background processing that respects your battery life.
*   **ML Kit (Google):** On-device OCR for privacy-focused text extraction.
*   **Coil:** Fast and efficient image loading.

## 📱 Getting Started
1.  Install the app.
2.  Grant the required Media/Storage permissions.
3.  RecallOS will perform an initial scan of your screenshots.
4.  Start searching or filtering by tags!

---
*RecallOS - Because your screenshots shouldn't be a black hole.*
