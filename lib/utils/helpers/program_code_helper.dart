class ProgramCodeHelper {
  static const Map<int, Map<String, String>> _codeDetails = {
    -1: {
      'button': "Paused Couldn't",
      'description': "Paused Couldn't Start",
    },
    1: {
      'button': "Start Manually",
      'description': "Start Manually",
    },
    -2: {
      'button': "Cond Couldn't",
      'description': "Started By Condition Couldn't Stop",
    },
    7: {
      'button': "Stop Manually",
      'description': "Stop Manually",
    },
    13: {
      'button': "Bypass Start",
      'description': "Bypass Start Condition",
    },
    11: {
      'button': "Bypass Cond",
      'description': "Bypass Condition",
    },
    12: {
      'button': "Bypass Stop",
      'description': "Bypass Stop Condition and Start",
    },
    0: {
      'button': "Stop Manually",
      'description': "Stop Manually",
    },
    2: {
      'button': "Pause",
      'description': "Pause",
    },
    3: {
      'button': "Resume",
      'description': "Resume",
    },
    4: {
      'button': "Cont Manually",
      'description': "Continue Manually",
    },
    -3: {
      'button': "Started By Rtc",
      'description': "Started By Rtc Couldn't Stop",
    },
    5: {
      'button': "Bypass Start Rtc",
      'description': "ByPass And Start By Rtc",
    },
    -4: {
      'button': "Cond Couldn't",
      'description': "Stopped by Condition, Couldn't bypass and Start",
    },
    6: {
      'button': "Bypass",
      'description': "Bypass Cyclic Off Time",
    },

  };

  static String getButtonName(int code) {
    return _codeDetails[code]?['button'] ?? 'Code not found';
  }

  static String getDescription(int code) {
    return _codeDetails[code]?['description'] ?? 'Code not found';
  }
}