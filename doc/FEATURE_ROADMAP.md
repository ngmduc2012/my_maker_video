# MyMakerVideo feature roadmap

This document records potential additions after the Flutter 3.47 upgrade. It
is a proposal, not a promise that these APIs already exist.

## Goals

- Keep the four existing methods backwards compatible.
- Provide safe typed arguments instead of exposing raw command strings.
- Make long-running work observable and cancellable.
- Keep input/output storage decisions in the host application.
- Add integration tests for every new FFmpeg flow.

## Recommended delivery order

### Phase 1: media information, progress, and cancellation

1. Add a typed `inspectMedia` API backed by FFprobe. Return duration, width,
   height, rotation, codecs, bitrate, frame rate, and audio/video stream data.
2. Add an asynchronous job handle with a unique session ID, a progress stream,
   a result future, and `cancel()`.
3. Calculate percentage progress from FFmpeg statistics and probed duration.
4. Delete partial output files when a task is cancelled or fails, unless the
   caller explicitly asks to keep them.

Why first: encoding can take minutes on a phone. Progress and cancellation are
more useful to application UX than adding another blocking helper, and the same
job API can support all later operations.

### Phase 2: common editing operations

1. `extractThumbnail`: save a JPEG/PNG frame at a timestamp with optional width
   and height.
2. `trimVideo`: accept start and duration/end. Offer an accurate re-encode mode
   and a fast stream-copy mode with documented keyframe limitations.
3. `compressVideo`: replace ambiguous percentages with presets or explicit
   `crf`, maximum dimensions, video codec, audio bitrate, and encoder preset.
4. `resizeVideo`, `cropVideo`, and `rotateVideo`: typed geometry with validation
   and automatic even H.264 dimensions.

Why next: these cover preview creation, sharing, upload limits, and lightweight
editing without requiring a full timeline editor.

### Phase 3: composition and audio

1. `mergeVideos`: concatenate compatible clips without quality loss, with an
   optional normalize-and-re-encode mode for mixed codecs or dimensions.
2. `extractAudio` and `muteVideo`.
3. `replaceAudio` or `addBackgroundAudio`, including volume, fade, looping, and
   shortest/longest duration behavior.
4. Position presets for watermarks (`topLeft`, `topRight`, `bottomLeft`,
   `bottomRight`, `center`) plus margin and opacity.

Concatenation needs careful validation. Stream-copy is fast but inputs must be
compatible; mixed media usually requires normalization and re-encoding.

### Phase 4: quality and creator features

1. Upgrade GIF output to a palette generation/use pipeline, with dithering and
   loop controls, for better color and compression than the current single-pass
   GIF helper.
2. Burn subtitles into video, or copy supported subtitle streams.
3. Add text watermark/caption support with caller-supplied font files.
4. Batch jobs with bounded concurrency and per-item results.

These are valuable but have more codec, font, temporary-file, performance, and
platform edge cases than Phases 1 and 2.

## Proposed API principles

- Keep `MyMakerVideo.ffmpegKit` and all current method signatures working.
- Introduce typed value objects for media information, progress, trim ranges,
  compression options, dimensions, and positions.
- Use argument lists internally for every path and user value.
- Validate values in Dart before starting native work.
- Return structured error categories in addition to a readable message.
- Never use a global progress callback to represent multiple jobs; route events
  by FFmpeg session ID.
- Do not expose a raw string-command API as the primary public interface.

## Important implementation constraints

- FFmpeg progress is time-based. A reliable percentage needs media duration
  from FFprobe and must handle unknown-duration inputs.
- Cancellation can leave a partial file; cleanup behavior must be deterministic.
- Fast trim and merge modes use stream copy. They are lossless and fast, but
  cuts may align to nearby keyframes and incompatible inputs can fail.
- Filters such as crop, overlay, scale, subtitles, and palette generation
  require decoding and re-encoding.
- Mobile operating systems can suspend or terminate background work. The first
  job API should promise in-app progress, not guaranteed background execution.
- Large media can consume significant CPU, battery, storage, and temporary
  space. Batch processing must cap concurrency.
- The bundled FFmpeg build includes GPL codecs. New features do not remove the
  application's existing license-compliance obligations.

## Test requirements for every new operation

1. Unit-test exact FFmpeg argument lists, validation, success, cancellation,
   and native failure mapping.
2. Run an integration test that generates and probes a real output file.
3. Verify paths containing whitespace and quote characters.
4. Verify missing audio, unusual rotation metadata, odd dimensions, and short
   inputs when relevant.
5. Test cancellation and confirm partial-file cleanup.
6. Build and run on both Android and iOS before release; record any platform not
   exercised on a real device.

## Suggested first release scope

The smallest high-value release is:

1. `inspectMedia`.
2. A progress/cancellation job abstraction.
3. `extractThumbnail`.
4. `trimVideo` with accurate and fast modes.
5. Unit and Android/iOS integration coverage plus complete usage examples.

After that foundation is stable, compression presets and merge/audio helpers
can be added without inventing a second execution model.

## Technical references

- [`ffmpeg_kit_flutter_new` API](https://pub.dev/documentation/ffmpeg_kit_flutter_new/latest/ffmpeg_kit/FFmpegKit-class.html): asynchronous argument execution, statistics callbacks, sessions, and cancellation.
- [`FFprobeKit` API](https://pub.dev/documentation/ffmpeg_kit_flutter_new/latest/ffprobe_kit/FFprobeKit-class.html): typed entry points for extracting media information.
- [FFprobe documentation](https://ffmpeg.org/ffprobe.html): formats, streams, codecs, duration, and metadata inspection.
- [FFmpeg documentation](https://ffmpeg.org/ffmpeg.html): seeking, trimming, stream selection, transcoding, and lossless stream copy.
- [FFmpeg filter documentation](https://ffmpeg.org/ffmpeg-filters.html): crop, scale, overlay, subtitle, palette generation, and GIF palette use.
- [FFmpeg format documentation](https://ffmpeg.org/ffmpeg-formats.html#concat): concat input rules and compatibility constraints.
