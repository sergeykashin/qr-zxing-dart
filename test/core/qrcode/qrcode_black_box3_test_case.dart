/*
 * Copyright 2008 ZXing authors
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
import 'package:zxing/zxing.dart';

import '../common/abstract_black_box.dart';

/**
 * @author dswitkin@google.com (Daniel Switkin)
 */
void main(){

  test('QRCodeBlackBox3TestCase', () {
    AbstractBlackBoxTestCase("src/test/resources/blackbox/qrcode-3", new MultiFormatReader(), BarcodeFormat.QR_CODE)
    ..addTest(38, 38, 0.0)
    ..addTest(39, 39, 90.0)
    ..addTest(36, 36, 180.0)
    ..addTest(39, 39, 270.0)
        ..testBlackBox();
  });

}