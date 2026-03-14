# Competitive Audit: Timetable Master

## Observations
- **Conflict Heatmaps**: Timetable Master employs immediate visual feedback during drag-and-drop operations. When a user holds a lesson, the entire grid highlights valid placements (often in green) and implicitly or explicitly marks conflicts (red) based on teacher or room availability.
- **Manual Drag-and-Drop Overrides**: The app allows users to drop a lesson even in conflicting slots, but immediately displays a warning dialog or visually flags the cell as conflicting post-drop. It doesn't strictly prevent the drop, treating the user as the ultimate authority.

## Gap Analysis
- **Our Current State**: The SmartTime AI `UniversalTimetableGrid` only provides a generic hover state (`tertiaryContainer` background) when dragging items over empty slots. It has no awareness of domain logic (conflicts) during the drag interaction.
- **Feature Expansion Strategy**: We need to implement a 'Conflict Glow' feature. By evaluating constraints (teacher overlap, class overlap, room availability) in real-time during a drag gesture, we can highlight valid slots in soft green and invalid slots in Mother Espresso/Red. This matches the competitive standard established by Timetable Master while keeping our aesthetic (Mother Sage).
