# notsince design system

The app uses warm paper, considered spacing, rounded forms, and growth as its
visual metaphor. Fonts and illustrations are local assets or Flutter painting;
the interface never needs a network connection.

## Tokens

| Role | Light | Dark |
| --- | --- | --- |
| Background | `#FAF7F0` | `#171513` |
| Surface | `#FFFDF8` | `#1E1C1A` |
| Ink | `#302C27` | `#F3EDE3` |
| Secondary ink | `#797168` | `#B6ACA0` |
| Default accent | `#639922` | Light accent mixed with 10% white |
| Hairline | Ink at 10%, 0.7dp | Pale ink at 2%, 0.7dp |

`lib/theme/app_colors.dart` owns new semantic tokens. `NsColors` remains a
compatibility extension for existing screens. Dark mode has independent charcoal
surfaces and restrained tinted cards, rather than inverted light colors.
Onboarding's accent is stored as ARGB and applied to the app theme and navigation.
Habit ARGB overrides live in Planner state, keyed by stable Tracker ID; existing
palette indexes remain readable. Projects store their ARGB directly.

Typography is bundled Baloo 2 for headings and Quicksand for reading:
display 28, title 22, body 16 with 1.5 leading, caption 13 with 1.4 leading.
Legacy oversized counter numbers remain oversized because their scale conveys
the original elapsed-days function.

Spacing uses an 8dp grid: 8, 16, 24, 32, 48. Cards normally use 24dp padding;
task rows use 16dp. Card radii are 24dp, navigation 28dp, compact surfaces 16dp,
and chips/buttons use pill shapes. Tiny heatmap cells and painted plant parts
have proportionally smaller radii. Cards use a 4–5% black shadow with 18–20dp
blur and a 4–6dp vertical offset. Only the Today timer hero has a duotone wash.

## Components and compatibility

- `SoftCard`: warm surface, hairline border, soft shadow, optional hero gradient.
- `PrimaryButton`: rounded Material button with at least 48×52dp targets.
- `AppChip`: pill filter with selected semantics.
- `HabitCircle`: progress ring, habit label, optional plant art, tap for detail,
  long press for quick check-in, accessible long-press action.
- `PlantIllustration`: offline CustomPainter seed, sprout, sapling, and bloom.
- The floating five-tab bar is CustomPaint, with a raised center Garden icon.
- Existing `StickerCard`, `StickerButton`, and `StickerSwitch` APIs retain their
  signatures while using the new borders, shadows, spacing, and press behavior.

This compatibility layer gives every existing screen the new visual language
without rewriting repositories, notification services, or counter logic.

## Motion

| Interaction | Duration | Behavior |
| --- | --- | --- |
| Button press | 120ms | Small vertical response, ease-out |
| Switch | 160ms | Retargetable alignment and fill |
| Tab selection | 200ms | Small raised selected icon |
| Task completion | 280ms | Brief confirmation interval before persisted completion |
| Plant entrance | 280ms | Restrained scale from 0.95 to 1 |
| Every successful check-in | 320ms | `flutter_animate` scale pulse 1 → 1.09 → 1 and ten painted sparkles |
| Growth celebration | 700ms | Full-screen plant bloom with elastic scale; explicit dismissal |

Check-in progress commits independently of the animation. A stage celebration
opens after the check-in feedback. Completed habits do not accumulate duplicate
check-ins. Numeric goals require reaching today's target before watering counts
as a completed day. Reduced motion uses immediate ring/state updates, suppresses
sparkles and scaling, and removes navigation/press/switch movement.

See `UI_MIGRATION.md` for screen-level mapping and `WALKTHROUGH.md` for validation.
