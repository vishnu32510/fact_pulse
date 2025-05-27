# Fact Pulse

A Flutter application that uses Perplexity’s Sonar API to provide real-time fact-checking for images and spoken content. Fact Pulse helps users verify information on-the-fly during debates, presentations, or when analyzing images containing claims.

---

## Features

* **Real-time Speech Analysis**
  Transcribes spoken content and fact-checks statements on the fly.
* **Image Fact Verification**
  Analyzes images and provides fact-checking for visual content.
* **Claim Rating System**
  Categorizes claims as **TRUE**, **FALSE**, **MISLEADING**, or **UNVERIFIABLE**.
* **Source Citations**
  Provides reliable sources for each fact-check.
* **User Authentication**
  Secure login with Firebase (Google, Apple, Email).
* **Debate Mode**
  Continuous speech recognition during live debates, with instant fact feedback.
* **Firestore Integration**
  Persists transcripts and fact-checks for future reference.
* **Cross-platform**
  Supports iOS, Android, and Web.

---

## Technical Implementation

### Architecture & State Management

Built with Flutter and the BLoC pattern for a clean separation between UI and logic.

* **Authentication**
  Firebase Auth (Google, Apple, Email)
* **Debate Analysis**
  `speech_to_text` for streaming transcription + Perplexity Sonar API for fact checks
* **Image Analysis**
  Upload or URL-reference images to Sonar API, extract and verify on-image text
* **Data Layer**
  Firestore collections per user → debates/images → transcriptions & claims

### Perplexity Integration

* **Prompt Engineering**
  Custom system prompts (in `lib/debate/prompts.dart`) instruct the model to:

  1. Extract verifiable factual claims (skip “um,” “I think,” etc.)
  2. Verify each claim against authoritative sources
  3. Return **pure JSON** with fields: `claim`, `rating`, `explanation`, `sources`
* **Request Flow**

  1. Capture speech chunks (≈7 words each) or image URL/base64
  2. Send to `PerplexityClient` (our Dart SDK)
  3. Parse JSON into `DebateResponseModel`
  4. Store each claim in Firestore and render in UI

### Firestore Schema

```
users/{uid}/debates/{debateId}/
  • claims (sub-collection)
  • { topic, createdAt, response, complete, updatedAt }

users/{uid}/speechs/{speechId}/
  • claims (sub-collection)
  • { topic, createdAt, response, complete, updatedAt }

users/{uid}/images/{imageId}/
  • claims (sub-collection)
  • { topic, createdAt, response, complete, lastOpenedAt }
```

---

## Open-Source Packages

* **perplexity\_dart**
  A lightweight, type-safe Dart SDK for Perplexity’s chat/completions API (streaming + non-streaming).
  [pub.dev](https://pub.dev/packages/perplexity_dart) • [GitHub](https://github.com/vishnu32510/perplexity_dart)
* **perplexity\_flutter**
  Flutter-specific wrapper + widgets for easier integration.
  [pub.dev](https://pub.dev/packages/perplexity_flutter) • [GitHub](https://github.com/vishnu32510/perplexity_flutter)

---

## Hackathon Categories

* **Primary**: Information Tools
* **Bonus**: Education

---

## Demo

📺 [Watch the demo video](#)

---

## Setup & Run

1. **Clone**

   ```bash
   git clone https://github.com/vishnu32510/fact_pulse.git
   cd fact_pulse
   ```
2. **Dependencies**

   ```bash
   flutter pub get
   ```
3. **Firebase**

   * Create a Firebase project
   * Enable Auth (Google, Apple, Email) & Firestore
   * Add `google-services.json` / `GoogleService-Info.plist`
4. **API Key**

   * Set `PERPLEXITY_API_KEY` in your environment or `.env`
5. **Run**

   ```bash
   flutter run
   ```

---

## Future Roadmap

* Real-time collaborative sessions
* Video-conference integration
* Offline/cached fact-checks
* Misinformation analytics dashboard
* Browser extension for web content verification

---

## License

MIT License — see the [LICENSE](LICENSE) file for details.
