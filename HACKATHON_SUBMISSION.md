# Fact Dynamics - Perplexity Hackathon Submission

## Inspiration

In today's information-overloaded world, misinformation spreads faster than ever before. During a heated debate with friends about climate change, I realized how difficult it was to fact-check claims in real-time. This challenge inspired Fact Dynamics—a tool that leverages Perplexity's powerful Sonar API to provide instant, reliable fact-checking during conversations and for image-based claims.

The democratization of AI through accessible APIs like Perplexity's Sonar creates an opportunity to put powerful verification tools directly in users' hands, potentially transforming how we consume and verify information in our daily lives.

## What it does

Fact Dynamics is a cross-platform application that provides real-time fact-checking in two key scenarios:

1. **Live Debate Analysis**: The app listens to ongoing conversations in real-time, and sends the text to Perplexity's Sonar API. The API analyzes the content, identifies factual claims, verifies them against reliable sources, and returns structured results rating each claim as TRUE, FALSE, MISLEADING, or UNVERIFIABLE. FOR and AGAINST labels are also provided to indicate whether the claim supports or opposes the debate topic.

1. **Live Speech Analysis**: The app listens to transcribes speech in real-time, and sends the text to Perplexity's Sonar API. The API analyzes the content, identifies factual claims, verifies them against reliable sources, and returns structured results rating each claim as TRUE, FALSE, MISLEADING, or UNVERIFIABLE.

2. **Image Verification**: Users can upload images containing text, charts, or claims. The Sonar API analyzes the visual content, extracts claims, and provides verification with source citations.

All fact-checks are stored in Firebase Firestore, allowing users to review past analyses and build a personal knowledge base of verified information. Ans prepare reports that can be downloaded and shared.

## How we built it

Fact Dynamics is built with Flutter using the BLoC pattern for state management, creating a clean separation between UI and business logic. The core components include:

1. **Perplexity API Integration**: I developed and open-sourced two packages to make Perplexity API integration seamless:
   - `perplexity_dart`: A type-safe Dart SDK for the Perplexity API
   - `perplexity_flutter`: Flutter-specific widgets and utilities

   Contributing to the Flutter community by open-sourcing these packages.

2. **Speech Processing**: Using the `speech_to_text` package to capture and transcribe spoken content in real-time.

3. **Prompt Engineering**: Carefully crafted system prompts in `lib/debate/prompts.dart` and `lib/image_fact/prompts.dart` that instruct the Sonar model to extract claims, verify them, and return structured JSON.

4. **Firebase Backend**: Authentication(Email, Google) and Firestore for persisting user data and fact-check results.

5. **Cross-Platform Support**: Optimized for iOS, Android, and [Web](https://fact-pulse.web.app/), with macOS support in testing.

## Challenges we ran into

1. **Prompt Engineering**: Crafting prompts that consistently extract factual claims from conversational text was challenging. I went through multiple iterations to find the right balance between sensitivity (catching all claims) and specificity (avoiding false positives).

2. **Real-time Processing**: Balancing the need for immediate feedback with API rate limits and response times required careful optimization of when and how often to send requests.

3. **Structured Output**: Ensuring the Perplexity API consistently returned well-structured JSON required extensive prompt refinement and robust error handling.

4. **Cross-Platform Media Handling**: Implementing image uploading and processing that works consistently across platforms required platform-specific optimizations.

5. **Resource Constraints**: Working within the limitations of API credits and free-tier Firebase services required thoughtful architecture decisions.

## Accomplishments that we're proud of

1. **Open Source Contributions**: Developing and publishing two packages that make Perplexity API integration easier for the entire Flutter ecosystem.

2. **Real-time Speech/Debate Fact-checking**: Successfully implementing a system that can analyze speech as it happens and provide immediate feedback.

3. **Real-time Report Fact-checking**: Successfully implementing a system that can analyze reports, extract claims, and provide immediate feedback.

4. **Structured Data Extraction**: Creating prompts that reliably extract structured data from unstructured conversational input.

5. **User Experience**: Building an intuitive interface that makes complex AI capabilities accessible to everyday users.

6. **Cross-Platform Support**: Delivering a consistent experience across multiple platforms from a single codebase.
***Android, iOS, Web, MacOS***

## What we learned

1. **Prompt Engineering**: The critical importance of precise prompt design when working with AI models, especially for structured data extraction.

2. **API Integration Patterns**: Best practices for integrating AI APIs into mobile applications, including error handling, rate limiting, and response processing.

3. **Flutter Architecture**: Advanced patterns for managing complex state and asynchronous operations in Flutter applications.

4. **AI Capabilities and Limitations**: A deeper understanding of what current AI models excel at and where they still need human oversight.

5. **Package Development**: The process of creating, testing, and publishing open-source packages that others can build upon.

6. **Perplexity API Capabilities**: Gained extensive knowledge about Perplexity's API ecosystem:
   - **Model Selection**: Understanding the tradeoffs between Sonar and SonarPro models for different use cases
   - **Multimodal Processing**: Leveraging the API's ability to analyze both text and images in a single request
   - **Response Formatting**: Using the API's JSON response capabilities for structured data extraction
   - **Context Management**: Optimizing prompt design to work within context window limitations
   - **Rate Limiting**: Implementing efficient request patterns to maximize API usage within quota constraints

7. **Structured Output Engineering**: Mastering techniques to guide Perplexity's models to consistently produce well-formed JSON responses that can be reliably parsed and displayed in a mobile application.

## What's next for Fact Dynamics

1. **Collaborative Sessions**: Enabling multiple users to join a fact-checking session, ideal for classroom discussions or team meetings.

2. **Video Integration**: Analyzing video content and providing real-time fact-checking for streaming media.

3. **Analytics Dashboard**: Creating visualizations of misinformation patterns to help users understand their information diet.

4. **Browser Extension**: Expanding to web browsers to verify content as users browse news and social media.

5. **Advanced Customization**: Allowing users to specify domains of interest and preferred sources for more personalized fact-checking.

The future of Fact Dynamics lies in making fact-checking so seamless and accessible that verifying information becomes a natural part of how we consume content in our increasingly complex information landscape.
