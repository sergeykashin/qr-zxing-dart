/*
 * Copyright 2016 ZXing authors
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


import 'package:flutter_test/flutter_test.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/oned.dart';
import 'package:zxing_lib/zxing.dart';

import '../utils.dart';

/// Tests [Code39Writer].
void main(){

  void doTest(String input, String expected) {
    BitMatrix result = new Code39Writer().encode(input, BarcodeFormat.CODE_39, 0, 0);
    expect(expected, matrixToString(result), reason: input);
  }

  test('testEncode', () {
    doTest("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
           "000001001011011010110101001011010110100101101101101001010101011001011011010110010101" +
           "011011001010101010011011011010100110101011010011010101011001101011010101001101011010" +
           "100110110110101001010101101001101101011010010101101101001010101011001101101010110010" +
           "101101011001010101101100101100101010110100110101011011001101010101001011010110110010" +
           "110101010011011010101010011011010110100101011010110010101101101100101010101001101011" +
           "01101001101010101100110101010100101101101101001011010101100101101010010110110100000");

    // extended mode blocks
    doTest("\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\b\t\n\u000b\f\r\u000e\u000f\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001a\u001b\u001c\u001d\u001e\u001f",
           "000001001011011010101001001001011001010101101001001001010110101001011010010010010101" +
           "011010010110100100100101011011010010101001001001010101011001011010010010010101101011" +
           "001010100100100101010110110010101001001001010101010011011010010010010101101010011010" +
           "100100100101010110100110101001001001010101011001101010010010010101101010100110100100" +
           "100101010110101001101001001001010110110101001010010010010101010110100110100100100101" +
           "011010110100101001001001010101101101001010010010010101010101100110100100100101011010" +
           "101100101001001001010101101011001010010010010101010110110010100100100101011001010101" +
           "101001001001010100110101011010010010010101100110101010100100100101010010110101101001" +
           "001001010110010110101010010010010101001101101010101001001001011010100101101010010010" +
           "010101101001011010100100100101101101001010101001001001010101100101101010010010010110" +
           "101100101010010110110100000");

    doTest(' !"' r"#$%&'()*+,-./0123456789:;<=>?",
           "000001001011011010100110101101010010010100101101010010110100100101001010110100101101" +
           "001001010010110110100101010010010100101010110010110100100101001011010110010101001001" +
           "010010101101100101010010010100101010100110110100100101001011010100110101001001010010" +
           "101101001101010010010100101010110011010100100101001011010101001101001001010010101101" +
           "010011010010101101101100101011010100100101001011010110100101010011011010110100101011" +
           "010110010101101101100101010101001101011011010011010101011001101010101001011011011010" +
           "010110101011001011010100100101001010011011010101010010010010101101100101010100100100" +
           "101010100110110101001001001011010100110101010010010010101101001101010100100100101010" +
           "11001101010010110110100000");

    doTest("@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_",
           "0000010010110110101010010010010100110101011011010100101101011010010110110110100101010" +
           "101100101101101011001010101101100101010101001101101101010011010101101001101010101100" +
           "110101101010100110101101010011011011010100101010110100110110101101001010110110100101" +
           "010101100110110101011001010110101100101010110110010110010101011010011010101101100110" +
           "101010100101101011011001011010101001101101010101001001001011010101001101010010010010" +
           "101101010011010100100100101101101010010101001001001010101101001101010010010010110101" +
           "101001010010110110100000");

    doTest("`abcdefghijklmnopqrstuvwxyz{|}~",
           "000001001011011010101001001001011001101010101001010010010110101001011010010100100101" +
           "011010010110100101001001011011010010101001010010010101011001011010010100100101101011" +
           "001010100101001001010110110010101001010010010101010011011010010100100101101010011010" +
           "100101001001010110100110101001010010010101011001101010010100100101101010100110100101" +
           "001001010110101001101001010010010110110101001010010100100101010110100110100101001001" +
           "011010110100101001010010010101101101001010010100100101010101100110100101001001011010" +
           "101100101001010010010101101011001010010100100101010110110010100101001001011001010101" +
           "101001010010010100110101011010010100100101100110101010100101001001010010110101101001" +
           "010010010110010110101010010100100101001101101010101001001001010110110100101010010010" +
           "010101010110011010100100100101101010110010101001001001010110101100101010010010010101" +
           "011011001010010110110100000");
  });


}
