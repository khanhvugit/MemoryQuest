# MemoryQuest

An offline native SwiftUI iPhone app for learning five memory strategies, practising ten challenges in Computer Science or Biology, and constructing a ten-building city.

Open `MemoryQuestfinal.xcodeproj` in Xcode and run the `MemoryQuestfinal` scheme on an iPhone simulator. The project deployment target is iOS 26.6.

## Structure

- `MemoryQuestfinal/App`: shared navigation and root view.
- `Models`: educational content and Codable progress records.
- `Data`: bundled subject content, lesson content, and atomic local JSON persistence.
- `Features`: Home, lessons, challenge activities, city, progress/history, and settings.
- `Shared`: styling, reusable controls, and Canvas illustrations derived from the prototype geometry.
- `MemoryQuestTests`: eight focused Swift Testing checks.
- `ReferencePrototype/index 2.html`: original interactive design reference.

Lesson completion is shared across subjects. Attempts and concept reviews are subject-specific. Buildings are awarded on challenge completion, once per challenge across both subjects. Progress is stored locally in Application Support.

## Verification status

The app and test target build successfully for the iPhone 18 Pro simulator. All eight focused Swift Testing checks have passed (the full run passed seven; the additional activity-flow check passed after correcting a Biology checklist phrase). The activity-flow check covers all ten challenges in both subjects at Easy, Medium, and Hard, including completion, scoring, repeated taps, single attempt saves, and result navigation.

The challenge completion observer is kept outside the changing question view identity to prevent a blank screen after the final answer. Review history prioritises genuine subject-specific practice over sample filler. Keyboard dismissal, navigation tab selection, city preview details, and replay achievement labels have also been corrected.

Final simulator smoke verification is in progress.
