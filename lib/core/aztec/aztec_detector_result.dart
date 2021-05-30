/*
 * Copyright 2010 ZXing authors
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

import '../common/bit_matrix.dart';
import '../common/detector_result.dart';

import '../result_point.dart';

/**
 * <p>Extends {@link DetectorResult} with more information specific to the Aztec format,
 * like the number of layers and whether it's compact.</p>
 *
 * @author Sean Owen
 */
class AztecDetectorResult extends DetectorResult {
  final bool compact;
  final int nbDatablocks;
  final int nbLayers;

  AztecDetectorResult(BitMatrix bits, List<ResultPoint> points, this.compact,
      this.nbDatablocks, this.nbLayers)
      : super(bits, points);

  int getNbLayers() {
    return nbLayers;
  }

  int getNbDatablocks() {
    return nbDatablocks;
  }

  bool isCompact() {
    return compact;
  }
}
