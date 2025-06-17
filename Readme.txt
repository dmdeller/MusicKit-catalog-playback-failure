This sample app demonstrates an issue with MusicKit in which some albums from the catalog fail to play. When adding the individual tracks to the queue, some tracks are silently removed. No errors are thrown.

Selected test results:
- Album “Black Sands”: only 1 of 12 songs are added to queue. Track 12 starts playing - incorrect behavior
- Album “The North Borders”: 12 of 13 songs are added to queue. Track 1 starts playing - initially seems correct, but actually incorrect if you listen to the entire album and notice the skipped track
- Album “Migration”: all 12 songs are added to queue. Track 1 starts playing - correct behavior
- Album “Fragments”: all 12 songs are dded to queue. Track 1 starts playing - correct behavior
- Album “Animal Magic”: only 1 of 12 songs are added to queue. Track 5 starts playing - incorrect behavior

All of the above play as expected in Music.app.

Filed as FB18131975.
