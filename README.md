# Life Archive AI

Life Archive AI is a SwiftUI iOS scaffold for a local-first personal management app. It combines notes, file library management, local search, configurable AI-provider settings, and a privacy-first assistant flow.

The current build is a functional v1 foundation rather than the complete long-term feature set. It is designed to open in Xcode, run on iPhone or iPad, and continue expanding module by module.

## Current Features

- Five-tab SwiftUI shell: Home, Library, AI Chat, Search, Settings.
- Local JSON persistence for documents, notes, chat sessions, and app settings.
- File import through the iOS document picker.
- TXT and Markdown text extraction; PDF, Office, and image files are stored with placeholders for later parsing or OCR.
- Standard local search across titles, content, tags, summaries, and categories.
- AI chat flow that searches local evidence first and clearly reports when no evidence exists.
- Document detail view with metadata, extracted text, favorite state, local summary, keyword generation, and to-do generation.
- Configurable OpenAI-compatible AI provider fields: base URL, request path, API key, model, auth mode, and custom header name.
- Optional real AI chat requests with local context included; when provider settings are missing or a request fails, the app falls back to local evidence.
- Task list with priority and optional due dates.
- Reminder list with repeat flags.
- Ledger entries with income, expense, categories, and monthly balance.
- Utility tools for text counts, trimming, and length conversion.
- Privacy vault placeholder and local backup snapshot action.
- Generated cat AppIcon asset set and in-app mascot image.
- Dark mode toggle and privacy reminder.

## Project Structure

- `LifeArchiveAI.xcodeproj` - Xcode project.
- `LifeArchiveAI/Models.swift` - local data models.
- `LifeArchiveAI/Services.swift` - storage, parsing, search, and AI helper services.
- `LifeArchiveAI/ArchiveStore.swift` - app state and persistence.
- `LifeArchiveAI/*View.swift` - SwiftUI screens and reusable components.
- `LifeArchiveAI/Assets.xcassets/AppIcon.appiconset` - generated iOS app icon set.

## Build In Xcode

1. Open `LifeArchiveAI.xcodeproj`.
2. Select the `LifeArchiveAI` target.
3. In Signing & Capabilities, choose your Apple Developer team.
4. If needed, change the bundle identifier from `com.codex.lifearchiveai` to a unique identifier.
5. Select an iPhone simulator or connected device.
6. Build and run.

## Self-Signing On iPhone

1. Connect the iPhone with a cable and trust the computer.
2. In Xcode, sign in with your Apple ID under Settings > Accounts.
3. Choose your personal team in Signing & Capabilities.
4. Build to the device.
5. If iOS blocks the app, open Settings > General > VPN & Device Management and trust the developer profile.

Free Apple ID signing may require reinstalling after the certificate expires and may have device or capability limitations.

## Build IPA With GitHub Actions

This repository includes `.github/workflows/build-ipa.yml`.

1. Upload all files in this folder to a GitHub repository.
2. Open the repository on GitHub.
3. Go to Actions.
4. Choose Build iOS IPA.
5. Click Run workflow.
6. After the workflow finishes, download the `LifeArchiveAI-unsigned-ipa` artifact.

The generated file is an unsigned IPA. Unsigned IPA files are useful for build verification and later re-signing. To install on a personal iPhone, sign the app with a valid Apple Developer certificate, use Xcode direct install, or re-sign the IPA with your own certificate and provisioning profile.

If GitHub Actions fails because a specific Xcode path is unavailable, edit `.github/workflows/build-ipa.yml` and update the `xcode-select` path to the Xcode version shown on the GitHub macOS runner.

## Implemented vs Pending

Implemented:

- App shell, basic UI, local persistence, imports, notes, search, settings, and app icon.
- Local-evidence-first AI answer flow without sending network requests by default.

Pending:

- Real Keychain storage for API keys.
- PDFKit text extraction.
- OCR and deep Office parsing.
- Streaming AI response handling.
- System notification scheduling, Face ID lock, encrypted private files, share-sheet backup export, and advanced photo tools.
- Automated Xcode build validation from macOS.

## Privacy Notes

The app is structured around local-first data handling. Imported files and generated JSON state stay in the app documents directory. The current AI chat does not call the network; it summarizes local search results and points to Settings for provider configuration.

Before enabling real provider requests, move API keys into Keychain and send only selected snippets, not full databases or entire private files.
