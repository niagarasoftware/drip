enum ScreenType {narrow, middle, wide}

enum UserRole {superAdmin, admin, dealer, customer, subUser}

enum MySegment {all, year}
enum MainMenuSegment {dashboard, product, stock}

enum GemProgramStartStopReasonCode {
  rs1(1, 'Running As Per Schedule'),
  rs2(2, 'Turned On Manually'),
  rs3(3, 'Started By Condition'),
  rs4(4, 'Turned Off Manually'),
  rs5(5, 'Program Turned Off'),
  rs6(6, 'Zone Turned Off'),
  rs7(7, 'Stopped By Condition'),
  rs8(8, 'Disabled By Condition'),
  rs9(9, 'Program started manually'),
  rs10(10, 'StandAlone Program Stopped'),
  rs11(11, 'StandAlone Program Stopped After Set Value'),
  rs12(12, 'StandAlone Manual Started'),
  rs13(13, 'StandAlone Manual Stopped'),
  rs14(14, 'StandAlone Manual Stopped After Set Value'),
  rs15(15, 'Started By Day Count Rtc'),
  rs16(16, 'Paused By User'),
  rs17(17, 'Manually Started Paused By User'),
  rs18(18, 'Program Deleted'),
  rs19(19, 'Program Ready'),
  rs20(20, 'Program Completed'),
  rs21(21, 'Resumed By User'),
  rs22(22, 'Paused By Condition'),
  rs23(23, 'Program Ready And Run By Condition'),
  rs24(24, 'Running As Per Schedule And Condition'),
  rs25(25, 'Started By Condition Paused By User'),
  rs26(26, 'Resumed By Condition'),
  rs27(27, 'Bypassed Start Condition Manually'),
  rs28(28, 'Bypassed Stop Condition Manually'),
  rs29(29, 'Continue Manually'),
  rs30(30, '-'),
  rs31(31, 'Program Completed'),
  rs32(32, 'Waiting For Condition'),
  rs33(33, 'Started By Condition and run as per Schedule'),
  rs34(34, 'Program running as per drip stand-alone mode'),
  unknown(0, 'Unknown content');

  final int code;
  final String content;

  const GemProgramStartStopReasonCode(this.code, this.content);

  static GemProgramStartStopReasonCode fromCode(int code) {
    return GemProgramStartStopReasonCode.values.firstWhere((e) => e.code == code,
      orElse: () => GemProgramStartStopReasonCode.unknown,
    );
  }
}

enum GemLineSSReasonCode {
  lss1(1, 'The Line Paused Manually'),
  lss2(2, 'Scheduled Program paused by Standalone program'),
  lss3(3, 'The Line Paused By System Definition'),
  lss4(4, 'The Line Paused By Low Flow Alarm'),
  lss5(5, 'The Line Paused By High Flow Alarm'),
  lss6(6, 'The Line Paused By No Flow Alarm'),
  lss7(7, 'The Line Paused By Ec High'),
  lss8(8, 'The Line Paused By Ph Low'),
  lss9(9, 'The Line Paused By Ph High'),
  lss10(10, 'The Line Paused By Pressure Low'),
  lss11(11, 'The Line Paused By Pressure High'),
  lss12(12, 'The Line Paused By No Power Supply'),
  lss13(13, 'The Line Paused By No Communication'),
  lss14(14, 'The Line Paused By Pump In Another Irrigation Line'),
  unknown(0, 'Unknown content');

  final int code;
  final String content;

  const GemLineSSReasonCode(this.code, this.content);

  static GemLineSSReasonCode fromCode(int code) {
    return GemLineSSReasonCode.values.firstWhere((e) => e.code == code,
      orElse: () => GemLineSSReasonCode.unknown,
    );
  }
}

enum PumpReasonCode {
  unknown(0, 'Unknown content'),

  // Motor OFF reasons
  motorOffSumpEmpty1(1, 'Motor off due to sump empty'),
  motorOffUpperTankFull1(2, 'Motor off due to upper tank full'),
  motorOffLowVoltage(3, 'Motor off due to low voltage'),
  motorOffHighVoltage(4, 'Motor off due to high voltage'),
  motorOffVoltageSPP(5, 'Motor off due to unbalanced voltage'),
  motorOffReversePhase(6, 'Motor off due to reverse phase'),
  motorOffStarterTrip(7, 'Motor off due to starter trip'),
  motorOffDryRun(8, 'Motor off due to dry run'),
  motorOffOverload(9, 'Motor off due to overload'),
  motorOffCurrentSPP(10, 'Motor off due to current SPP'),
  motorOffCyclicTrip(11, 'Motor off due to cyclic trip'),
  motorOffMaxRunTime(12, 'Motor off due to maximum run time'),
  motorOffSumpEmpty2(13, 'Motor off due to sump empty'),
  motorOffUpperTankFull2(14, 'Motor off due to upper tank full'),
  motorOffRTC1(15, 'Motor off due to RTC 1'),
  motorOffRTC2(16, 'Motor off due to RTC 2'),
  motorOffRTC3(17, 'Motor off due to RTC 3'),
  motorOffRTC4(18, 'Motor off due to RTC 4'),
  motorOffRTC5(19, 'Motor off due to RTC 5'),
  motorOffRTC6(20, 'Motor off due to RTC 6'),
  motorOffKeyOff(21, 'Motor off due to auto mobile key off'),

  // Motor ON reasons
  motorOnCyclicTime(22, 'Motor on due to cyclic time'),
  motorOnRTC1(23, 'Motor on due to RTC 1'),
  motorOnRTC2(24, 'Motor on due to RTC 2'),
  motorOnRTC3(25, 'Motor on due to RTC 3'),
  motorOnRTC4(26, 'Motor on due to RTC 4'),
  motorOnRTC5(27, 'Motor on due to RTC 5'),
  motorOnRTC6(28, 'Motor on due to RTC 6'),
  motorOnKeyOn(29, 'Motor on due to auto mobile key on'),
  motorOffPowerOff(30, 'Motor off due to Power off'),
  powerOn(31, 'Motor on due to Power on'),
  motorOffTN(32,'Motor off due to trip to normal'),
  motorOff2P(33,'Motor off due to 2phase'),
  motorOffPOn(34,'Motor off due to other pump is on'),
  motorOffPOff(35,'Motor off due to waiting for other pump to turn off'),
  motorOffPrsSwtHigh(36,'Motor off due to pressure switch high'),
  noComm(37,'Motor off due to no communication to nodes'),
  sumpCableDisconnected(38,'Motor off due to sump cable disconnected'),
  tankCableDisconnected(39,'Motor off due to tank cable disconnected'),
  sumpFloatFailed(40,'Motor off due to sump float failed'),
  tankFloatFailed(41,'Motor off due to tank float failed'),
  motorOffCyclicTimeCompleted(42, 'Motor off due to cycle completed'),
  motorOffDryRunOccurrence(43, 'Motor off due to dry run occurrence');

  final int code;
  final String content;

  const PumpReasonCode(this.code, this.content);

  static PumpReasonCode fromCode(int code) {
    return PumpReasonCode.values.firstWhere(
          (e) => e.code == code,
      orElse: () => PumpReasonCode.unknown,
    );
  }
}

enum BlueConnectionState {connected, connecting, disconnecting, disconnected}
enum MQTTConnectionState {connected, disconnected, connecting}