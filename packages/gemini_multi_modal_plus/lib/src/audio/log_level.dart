import 'package:flutter_pcm_sound/flutter_pcm_sound.dart' as fpcm;

enum LogLevel {
  none,
  error,
  standard,
  verbose;

  fpcmLogLevel() {
    switch (this) {
      case LogLevel.none:
        return fpcm.LogLevel.none;
      case LogLevel.error:
        return fpcm.LogLevel.error;
      case LogLevel.standard:
        return fpcm.LogLevel.standard;
      case LogLevel.verbose:
        return fpcm.LogLevel.verbose;
    }
  }
}
