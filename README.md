# Fact Pulse

A Flutter application that uses Perplexity’s Sonar API to provide real-time fact-checking for images and spoken content. Fact Pulse helps users verify information on-the-fly during debates, presentations, or when analyzing images containing claims.

## 🏆 Perplexity Hackathon Submission

**Category**: Information Tools  
**Bonus Category**: Education

## 📱 Demo & Screenshots

[Watch the demo video](#)

[Web Demo](https://fact-pulse.web.app/) - May remove later

<table>
  <tr>
    <td><img src="assets/screenshots/1. Login.png" width="200"/></td>
    <td><img src="assets/screenshots/2. Dashboard.png" width="200"/></td>
    <td><img src="assets/screenshots/5. Profile.png" width="200"/></td>
  </tr>
</table>

<table>
  <tr>
    <td><img src="assets/screenshots/3. Facts Checked List(Speech, Debate, Image).png" width="200"/></td>
    <td><img src="assets/screenshots/4. Fact Checks(Speech, Debate, Image).png" width="200"/></td>
  </tr>
</table>

## ✨ Features

* **Real-time Speech Analysis**
  Transcribes spoken content and fact-checks statements on the fly.
* **Image Fact Verification**
  Analyzes images and provides fact-checking for visual content.
* **Claim Rating System**
  Categorizes claims as **TRUE**, **FALSE**, **MISLEADING**, or **UNVERIFIABLE**.
* **Source Citations**
  Provides reliable sources for each fact-check.
* **User Authentication**
  Secure login with Firebase (Google, Email).
* **Debate Mode**
  Continuous speech recognition during live debates, with instant fact feedback.
* **Firestore Integration**
  Persists transcripts and fact-checks for future reference.
* **Cross-platform**
  Supports iOS, Android, and Web (macOS support in testing, Windows not currently supported).

## 🔍 Perplexity API Integration

Fact Pulse leverages Perplexity's Sonar API in several key ways:

1. **Debate Fact-Checking**:
   - Speech is transcribed in real-time using `speech_to_text`
   - Transcribed text is sent to Perplexity's Sonar API via our custom client
   - Carefully crafted prompts (in `lib/debate/prompts.dart`) instruct the model to:
     - Extract verifiable factual claims
     - Verify each claim against authoritative sources
     - Return structured JSON with claim, rating, explanation, and sources

2. **Image Analysis**:
   - Images are processed and sent to Sonar API
   - The API extracts text from images and identifies claims
   - Each claim is verified and rated for accuracy

3. **JSON Response Handling**:
   ```json
   {
     "claims": [
       {
         "claim": "Example factual statement",
         "rating": "TRUE|FALSE|MISLEADING|UNVERIFIABLE",
         "explanation": "Verification details",
         "sources": ["Source URL 1", "Source URL 2"]
       }
     ]
   }
   ```

## 📦 Open-Source Packages

As part of this project, I've developed and open-sourced two Dart packages to make Perplexity API integration easier for the Flutter community:

### perplexity_dart

A lightweight, type-safe Dart SDK for Perplexity's chat/completions API with both streaming and non-streaming support.

- [pub.dev](https://pub.dev/packages/perplexity_dart)
- [GitHub](https://github.com/vishnu32510/perplexity_dart)

Key features:
- Type-safe API client
- Streaming and non-streaming support
- Comprehensive error handling
- Customizable request options

### perplexity_flutter

Flutter-specific wrapper and widgets for easier Perplexity API integration in Flutter apps.

- [pub.dev](https://pub.dev/packages/perplexity_flutter)
- [GitHub](https://github.com/vishnu32510/perplexity_flutter)

Key features:
- Ready-to-use Flutter widgets
- Simplified state management
- Platform-specific optimizations
- Example implementations

## 🏗️ Technical Implementation

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

## 🚀 Impact & Innovation

Fact Pulse addresses the critical challenge of misinformation by:

1. **Democratizing Fact-Checking**: Puts powerful verification tools in everyone's hands
2. **Real-Time Analysis**: Provides immediate feedback during live conversations
3. **Educational Value**: Helps users learn to identify reliable information
4. **Open Source Contribution**: The packages we've developed make Perplexity's powerful API accessible to the entire Flutter ecosystem

## ⚠️ Current Limitations

* **Apple Sign-in**: Not currently implemented as it requires a paid Apple Developer membership
* **Firebase Storage**: Image and report storage is limited as Firebase Storage requires a paid subscription for larger storage needs
* **API Models**: Currently using only Sonar and SonarPro models due to limited Perplexity API credits
* **Platform Support**: Windows is not currently supported, and macOS support is still in testing

These limitations are primarily due to development resource constraints and would be addressed in a production environment.

## 🛠️ Setup & Run

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
   * Enable Auth (Google, Email) & Firestore
   * Add `google-services.json` / `GoogleService-Info.plist`
4. **API Key**

   * Set `PERPLEXITY_API_KEY` in your environment or `.env`
5. **Run**

   ```bash
   flutter run
   ```

## 🔮 Future Roadmap

* Real-time collaborative sessions
* Video-conference integration
* Offline/cached fact-checks
* Misinformation analytics dashboard
* Browser extension for web content verification

## 📄 License

MIT License — see the [LICENSE](LICENSE) file for details.
