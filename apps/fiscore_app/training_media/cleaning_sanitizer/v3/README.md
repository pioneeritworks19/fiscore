# Cleaning and Sanitizer Readiness - Version 3 Media

This lesson uses FiScore Library-owned media. Tenant training records and
training assignments reference immutable versioned files; the files are not
copied into each tenant.

## Required Files

Upload these files to Firebase Storage:

| Content | Storage path |
| --- | --- |
| Sanitizer test-strip instructional image | `fiscoreLibrary/training/cleaning_sanitizer/versions/3/media/med_sanitizer_strip_01/image.jpg` |
| Safe chemical-storage instructional image | `fiscoreLibrary/training/cleaning_sanitizer/versions/3/media/med_chemical_storage_01/image.jpg` |
| Required short demonstration video | `fiscoreLibrary/training/cleaning_sanitizer/versions/3/media/med_cleaning_demo_01/video.mp4` |

The supplied video source is:

```text
C:\Users\mkann\Downloads\cleaning_and_sanitation.MP4
```

Export a two-minute training excerpt from this source for the required watch
test. The full ten-minute video should not be required in a short lesson.

Each asset is represented in the library lesson's `mediaAssets` registry by
its `mediaId`; lesson blocks reference `mediaId`, not handwritten Storage
paths.

## Upload Example

```powershell
gcloud storage cp "<path-to-sanitizer-test-strips.jpg>" "gs://fiscore-dev.firebasestorage.app/fiscoreLibrary/training/cleaning_sanitizer/versions/3/media/med_sanitizer_strip_01/image.jpg"
gcloud storage cp "<path-to-chemical-storage.jpg>" "gs://fiscore-dev.firebasestorage.app/fiscoreLibrary/training/cleaning_sanitizer/versions/3/media/med_chemical_storage_01/image.jpg"
gcloud storage cp "<path-to-two-minute-cleaning-demo.mp4>" "gs://fiscore-dev.firebasestorage.app/fiscoreLibrary/training/cleaning_sanitizer/versions/3/media/med_cleaning_demo_01/video.mp4"
```

When an object is uploaded with Google Cloud tooling rather than from a
Firebase client, open it in the Firebase Storage Console and create an access
token if one is not already present. The mobile/web player uses Firebase
Storage download URLs to display library media.

Deploy updated Storage rules before staff view this media:

```powershell
firebase deploy --only storage --project fiscore-dev
```

## Upgrade Test

1. Assign the current `Cleaning and sanitizer readiness` lesson before updating.
2. Open `Explore FiScore` and confirm the lesson displays `Update`.
3. Update the lesson into My Library and assign the upgraded lesson.
4. Confirm the prior assignment still shows its original text content.
5. Confirm the new assignment renders version 3 visual content.
6. Confirm the learner cannot proceed from the video topic until the required
   two-minute video is watched.
