# Android acceptance checklist

- Import a clear synthetic English receipt, drag crop corners, rotate, preview, then recognize.
- Try Reset, Adjust crop, and back/cancel; cancellation should keep the previous document.
- Tap an extracted line, confirm the highlighted location, zoom, correct it, and export.
- Compare OCR with the cropped image.
- Capture a photo; cancel the camera; deny permission; confirm recovery.
- Import EXIF-rotated photos and verify image/text alignment.
- Correct a line and export. Search for the correction in two PDF viewers.
- Check selection alignment and copied text reading order.
- Turn on airplane mode, restart and repeat OCR.
- Try an image with no text and an unsupported/special character.
- Background the picker and test Android lost-data recovery.
- Test a large image and record responsiveness/memory use.

Device tests are pending; no Android device was connected during initial development.

## v0.0.3

- Confirm Text document exports visible text on white pages with no photo.
- Confirm Original scan still includes the image with searchable text.
- Save in app, close/restart, open Saved documents and reopen the same document.
- Edit a line, reorder lines, save again and verify one updated library entry.
- Preview and share the saved text PDF.
- Test empty OCR and unsupported text error messages.
