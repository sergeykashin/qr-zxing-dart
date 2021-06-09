/*
 * Copyright 2009 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import '../../common/bit_array.dart';
import '../../common/detector/math_utils.dart';
import '../../common/string_builder.dart';

import '../../barcode_format.dart';
import '../../decode_hint_type.dart';
import '../../not_found_exception.dart';
import '../../result.dart';
import '../../result_metadata_type.dart';
import '../../result_point.dart';
import '../../result_point_callback.dart';
import '../one_dreader.dart';
import 'abstract_rssreader.dart';
import 'data_character.dart';
import 'finder_pattern.dart';
import 'pair.dart';
import 'rssutils.dart';

/// Decodes RSS-14, including truncated and stacked variants. See ISO/IEC 24724:2006.
class RSS14Reader extends AbstractRSSReader {
  static const List<int> _OUTSIDE_EVEN_TOTAL_SUBSET = [1, 10, 34, 70, 126];
  static const List<int> _INSIDE_ODD_TOTAL_SUBSET = [4, 20, 48, 81];
  static const List<int> _OUTSIDE_GSUM = [0, 161, 961, 2015, 2715];
  static const List<int> _INSIDE_GSUM = [0, 336, 1036, 1516];
  static const List<int> _OUTSIDE_ODD_WIDEST = [8, 6, 4, 3, 1];
  static const List<int> _INSIDE_ODD_WIDEST = [2, 4, 6, 8];

  static const List<List<int>> _FINDER_PATTERNS = [
    [3, 8, 2, 1],
    [3, 5, 5, 1],
    [3, 3, 7, 1],
    [3, 1, 9, 1],
    [2, 7, 4, 1],
    [2, 5, 6, 1],
    [2, 3, 8, 1],
    [1, 5, 7, 1],
    [1, 3, 9, 1],
  ];

  final List<Pair> _possibleLeftPairs = [];
  final List<Pair> _possibleRightPairs = [];

  RSS14Reader();

  @override
  Result decodeRow(
      int rowNumber, BitArray row, Map<DecodeHintType, Object>? hints) {
    Pair? leftPair = _decodePair(row, false, rowNumber, hints);
    _addOrTally(_possibleLeftPairs, leftPair);
    row.reverse();
    Pair? rightPair = _decodePair(row, true, rowNumber, hints);
    _addOrTally(_possibleRightPairs, rightPair);
    row.reverse();
    for (Pair left in _possibleLeftPairs) {
      if (left.count > 1) {
        for (Pair right in _possibleRightPairs) {
          if (right.count > 1 && _checkChecksum(left, right)) {
            return _constructResult(left, right);
          }
        }
      }
    }
    throw NotFoundException.instance;
  }

  static void _addOrTally(List<Pair> possiblePairs, Pair? pair) {
    if (pair == null) {
      return;
    }
    bool found = false;
    for (Pair other in possiblePairs) {
      if (other.value == pair.value) {
        other.incrementCount();
        found = true;
        break;
      }
    }
    if (!found) {
      possiblePairs.add(pair);
    }
  }

  @override
  void reset() {
    _possibleLeftPairs.clear();
    _possibleRightPairs.clear();
  }

  static Result _constructResult(Pair leftPair, Pair rightPair) {
    int symbolValue = 4537077 * leftPair.value + rightPair.value;
    String text = symbolValue.toString();

    StringBuilder buffer = StringBuilder();
    for (int i = 13 - text.length; i > 0; i--) {
      buffer.write('0');
    }
    buffer.write(text);

    int checkDigit = 0;
    for (int i = 0; i < 13; i++) {
      int digit = buffer.codePointAt(i) - 48 /* 0 */;
      checkDigit += (i & 0x01) == 0 ? 3 * digit : digit;
    }
    checkDigit = 10 - (checkDigit % 10);
    if (checkDigit == 10) {
      checkDigit = 0;
    }
    buffer.write(checkDigit);

    List<ResultPoint> leftPoints =
        leftPair.finderPattern.resultPoints;
    List<ResultPoint> rightPoints =
        rightPair.finderPattern.resultPoints;
    Result result = Result(
        buffer.toString(),
        null,
        [
          leftPoints[0],
          leftPoints[1],
          rightPoints[0],
          rightPoints[1],
        ],
        BarcodeFormat.RSS_14);
    result.putMetadata(ResultMetadataType.SYMBOLOGY_IDENTIFIER, "]e0");
    return result;
  }

  static bool _checkChecksum(Pair leftPair, Pair rightPair) {
    int checkValue =
        (leftPair.checksumPortion + 16 * rightPair.checksumPortion) %
            79;
    int targetCheckValue = 9 * leftPair.finderPattern.value +
        rightPair.finderPattern.value;
    if (targetCheckValue > 72) {
      targetCheckValue--;
    }
    if (targetCheckValue > 8) {
      targetCheckValue--;
    }
    return checkValue == targetCheckValue;
  }

  Pair? _decodePair(BitArray row, bool right, int rowNumber,
      Map<DecodeHintType, Object>? hints) {
    try {
      List<int> startEnd = _findFinderPattern(row, right);
      FinderPattern pattern =
          _parseFoundFinderPattern(row, rowNumber, right, startEnd);

      ResultPointCallback? resultPointCallback = hints == null
          ? null
          : hints[DecodeHintType.NEED_RESULT_POINT_CALLBACK]
              as ResultPointCallback;

      if (resultPointCallback != null) {
        startEnd = pattern.startEnd;
        double center = (startEnd[0] + startEnd[1] - 1) / 2.0;
        if (right) {
          // row is actually reversed
          center = row.size - 1 - center;
        }
        resultPointCallback.foundPossibleResultPoint(
            ResultPoint(center, rowNumber.toDouble()));
      }

      DataCharacter outside = _decodeDataCharacter(row, pattern, true);
      DataCharacter inside = _decodeDataCharacter(row, pattern, false);
      return Pair(
          1597 * outside.value + inside.value,
          outside.checksumPortion + 4 * inside.checksumPortion,
          pattern);
    } catch (ignored) {
      // NotFoundException
      return null;
    }
  }

  DataCharacter _decodeDataCharacter(
      BitArray row, FinderPattern pattern, bool outsideChar) {
    List<int> counters = getDataCharacterCounters();
    // Arrays.fill(counters, 0);

    if (outsideChar) {
      OneDReader.recordPatternInReverse(
          row, pattern.startEnd[0], counters);
    } else {
      OneDReader.recordPattern(row, pattern.startEnd[1], counters);
      // reverse it
      for (int i = 0, j = counters.length - 1; i < j; i++, j--) {
        int temp = counters[i];
        counters[i] = counters[j];
        counters[j] = temp;
      }
    }

    int numModules = outsideChar ? 16 : 15;
    double elementWidth = MathUtils.sum(counters) / numModules;

    List<int> oddCounts = this.getOddCounts();
    List<int> evenCounts = this.getEvenCounts();
    List<double> oddRoundingErrors = this.getOddRoundingErrors();
    List<double> evenRoundingErrors = this.getEvenRoundingErrors();

    for (int i = 0; i < counters.length; i++) {
      double value = counters[i] / elementWidth;
      int count = (value + 0.5).toInt(); // Round
      if (count < 1) {
        count = 1;
      } else if (count > 8) {
        count = 8;
      }
      int offset = i ~/ 2;
      if ((i & 0x01) == 0) {
        oddCounts[offset] = count;
        oddRoundingErrors[offset] = value - count;
      } else {
        evenCounts[offset] = count;
        evenRoundingErrors[offset] = value - count;
      }
    }

    _adjustOddEvenCounts(outsideChar, numModules);

    int oddSum = 0;
    int oddChecksumPortion = 0;
    for (int i = oddCounts.length - 1; i >= 0; i--) {
      oddChecksumPortion *= 9;
      oddChecksumPortion += oddCounts[i];
      oddSum += oddCounts[i];
    }
    int evenChecksumPortion = 0;
    int evenSum = 0;
    for (int i = evenCounts.length - 1; i >= 0; i--) {
      evenChecksumPortion *= 9;
      evenChecksumPortion += evenCounts[i];
      evenSum += evenCounts[i];
    }
    int checksumPortion = oddChecksumPortion + 3 * evenChecksumPortion;

    if (outsideChar) {
      if ((oddSum & 0x01) != 0 || oddSum > 12 || oddSum < 4) {
        throw NotFoundException.instance;
      }
      int group = (12 - oddSum) ~/ 2;
      int oddWidest = _OUTSIDE_ODD_WIDEST[group];
      int evenWidest = 9 - oddWidest;
      int vOdd = RSSUtils.getRSSvalue(oddCounts, oddWidest, false);
      int vEven = RSSUtils.getRSSvalue(evenCounts, evenWidest, true);
      int tEven = _OUTSIDE_EVEN_TOTAL_SUBSET[group];
      int gSum = _OUTSIDE_GSUM[group];
      return DataCharacter(vOdd * tEven + vEven + gSum, checksumPortion);
    } else {
      if ((evenSum & 0x01) != 0 || evenSum > 10 || evenSum < 4) {
        throw NotFoundException.instance;
      }
      int group = (10 - evenSum) ~/ 2;
      int oddWidest = _INSIDE_ODD_WIDEST[group];
      int evenWidest = 9 - oddWidest;
      int vOdd = RSSUtils.getRSSvalue(oddCounts, oddWidest, true);
      int vEven = RSSUtils.getRSSvalue(evenCounts, evenWidest, false);
      int tOdd = _INSIDE_ODD_TOTAL_SUBSET[group];
      int gSum = _INSIDE_GSUM[group];
      return DataCharacter(vEven * tOdd + vOdd + gSum, checksumPortion);
    }
  }

  List<int> _findFinderPattern(BitArray row, bool rightFinderPattern) {
    List<int> counters = getDecodeFinderCounters();
    counters[0] = 0;
    counters[1] = 0;
    counters[2] = 0;
    counters[3] = 0;

    int width = row.size;
    bool isWhite = false;
    int rowOffset = 0;
    while (rowOffset < width) {
      isWhite = !row.get(rowOffset);
      if (rightFinderPattern == isWhite) {
        // Will encounter white first when searching for right finder pattern
        break;
      }
      rowOffset++;
    }

    int counterPosition = 0;
    int patternStart = rowOffset;
    for (int x = rowOffset; x < width; x++) {
      if (row.get(x) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == 3) {
          if (AbstractRSSReader.isFinderPattern(counters)) {
            return [patternStart, x];
          }
          patternStart += counters[0] + counters[1];
          counters[0] = counters[2];
          counters[1] = counters[3];
          counters[2] = 0;
          counters[3] = 0;
          counterPosition--;
        } else {
          counterPosition++;
        }
        counters[counterPosition] = 1;
        isWhite = !isWhite;
      }
    }
    throw NotFoundException.instance;
  }

  FinderPattern _parseFoundFinderPattern(
      BitArray row, int rowNumber, bool right, List<int> startEnd) {
    // Actually we found elements 2-5
    bool firstIsBlack = row.get(startEnd[0]);
    int firstElementStart = startEnd[0] - 1;
    // Locate element 1
    while (
        firstElementStart >= 0 && firstIsBlack != row.get(firstElementStart)) {
      firstElementStart--;
    }
    firstElementStart++;
    int firstCounter = startEnd[0] - firstElementStart;
    // Make 'counters' hold 1-4
    List<int> counters = getDecodeFinderCounters();
    List.copyRange(counters, 1, counters, 0, counters.length - 1);

    counters[0] = firstCounter;
    int value = AbstractRSSReader.parseFinderValue(counters, _FINDER_PATTERNS);
    int start = firstElementStart;
    int end = startEnd[1];
    if (right) {
      // row is actually reversed
      start = row.size - 1 - start;
      end = row.size - 1 - end;
    }
    return FinderPattern(
        value, [firstElementStart, startEnd[1]], start, end, rowNumber);
  }

  void _adjustOddEvenCounts(bool outsideChar, int numModules) {
    int oddSum = MathUtils.sum(getOddCounts());
    int evenSum = MathUtils.sum(getEvenCounts());

    bool incrementOdd = false;
    bool decrementOdd = false;
    bool incrementEven = false;
    bool decrementEven = false;

    if (outsideChar) {
      if (oddSum > 12) {
        decrementOdd = true;
      } else if (oddSum < 4) {
        incrementOdd = true;
      }
      if (evenSum > 12) {
        decrementEven = true;
      } else if (evenSum < 4) {
        incrementEven = true;
      }
    } else {
      if (oddSum > 11) {
        decrementOdd = true;
      } else if (oddSum < 5) {
        incrementOdd = true;
      }
      if (evenSum > 10) {
        decrementEven = true;
      } else if (evenSum < 4) {
        incrementEven = true;
      }
    }

    int mismatch = oddSum + evenSum - numModules;
    bool oddParityBad = (oddSum & 0x01) == (outsideChar ? 1 : 0);
    bool evenParityBad = (evenSum & 0x01) == 1;
    /*if (mismatch == 2) {
      if (!(oddParityBad && evenParityBad)) {
        throw ReaderException.getInstance();
      }
      decrementOdd = true;
      decrementEven = true;
    } else if (mismatch == -2) {
      if (!(oddParityBad && evenParityBad)) {
        throw ReaderException.getInstance();
      }
      incrementOdd = true;
      incrementEven = true;
    } else */
    switch (mismatch) {
      case 1:
        if (oddParityBad) {
          if (evenParityBad) {
            throw NotFoundException.instance;
          }
          decrementOdd = true;
        } else {
          if (!evenParityBad) {
            throw NotFoundException.instance;
          }
          decrementEven = true;
        }
        break;
      case -1:
        if (oddParityBad) {
          if (evenParityBad) {
            throw NotFoundException.instance;
          }
          incrementOdd = true;
        } else {
          if (!evenParityBad) {
            throw NotFoundException.instance;
          }
          incrementEven = true;
        }
        break;
      case 0:
        if (oddParityBad) {
          if (!evenParityBad) {
            throw NotFoundException.instance;
          }
          // Both bad
          if (oddSum < evenSum) {
            incrementOdd = true;
            decrementEven = true;
          } else {
            decrementOdd = true;
            incrementEven = true;
          }
        } else {
          if (evenParityBad) {
            throw NotFoundException.instance;
          }
          // Nothing to do!
        }
        break;
      default:
        throw NotFoundException.instance;
    }

    if (incrementOdd) {
      if (decrementOdd) {
        throw NotFoundException.instance;
      }
      AbstractRSSReader.increment(getOddCounts(), getOddRoundingErrors());
    }
    if (decrementOdd) {
      AbstractRSSReader.decrement(getOddCounts(), getOddRoundingErrors());
    }
    if (incrementEven) {
      if (decrementEven) {
        throw NotFoundException.instance;
      }
      AbstractRSSReader.increment(getEvenCounts(), getOddRoundingErrors());
    }
    if (decrementEven) {
      AbstractRSSReader.decrement(getEvenCounts(), getEvenRoundingErrors());
    }
  }
}