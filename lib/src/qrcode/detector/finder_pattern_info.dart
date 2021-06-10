/*
 * Copyright 2007 ZXing authors
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

import 'finder_pattern.dart';

/// Encapsulates information about finder patterns in an image, including the location of
/// the three finder patterns, and their estimated module size.
///
/// @author Sean Owen
class FinderPatternInfo {
  final FinderPattern _bottomLeft;
  final FinderPattern _topLeft;
  final FinderPattern _topRight;

  FinderPatternInfo(List<FinderPattern> patternCenters)
      : this._bottomLeft = patternCenters[0],
        this._topLeft = patternCenters[1],
        this._topRight = patternCenters[2];

  FinderPattern get bottomLeft => _bottomLeft;

  FinderPattern get topLeft => _topLeft;

  FinderPattern get topRight => _topRight;
}
