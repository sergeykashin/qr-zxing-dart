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

import 'result_parser.dart';
import '../../result.dart';
import 'abstract_do_co_mo_result_parser.dart';
import 'address_book_parsed_result.dart';

/// Implements the "MECARD" address book entry format.
///
/// Supported keys: N, SOUND, TEL, EMAIL, NOTE, ADR, BDAY, URL, plus ORG
/// Unsupported keys: TEL-AV, NICKNAME
///
/// Except for TEL, multiple values for keys are also not supported;
/// the first one found takes precedence.
///
/// Our understanding of the MECARD format is based on this document:
///
/// http://www.mobicode.org.tw/files/OMIA%20Mobile%20Bar%20Code%20Standard%20v3.2.1.doc
///
/// @author Sean Owen
class AddressBookDoCoMoResultParser extends AbstractDoCoMoResultParser {
  @override
  AddressBookParsedResult? parse(Result result) {
    String rawText = ResultParser.getMassagedText(result);
    if (!rawText.startsWith("MECARD:")) {
      return null;
    }
    List<String>? rawName = AbstractDoCoMoResultParser.matchDoCoMoPrefixedField("N:", rawText);
    if (rawName == null) {
      return null;
    }
    String name = _parseName(rawName[0]);
    String? pronunciation =
    AbstractDoCoMoResultParser.matchSingleDoCoMoPrefixedField("SOUND:", rawText, true);
    List<String>? phoneNumbers = AbstractDoCoMoResultParser.matchDoCoMoPrefixedField("TEL:", rawText);
    List<String>? emails = AbstractDoCoMoResultParser.matchDoCoMoPrefixedField("EMAIL:", rawText);
    String? note = AbstractDoCoMoResultParser.matchSingleDoCoMoPrefixedField("NOTE:", rawText, false);
    List<String>? addresses = AbstractDoCoMoResultParser.matchDoCoMoPrefixedField("ADR:", rawText);
    String? birthday = AbstractDoCoMoResultParser.matchSingleDoCoMoPrefixedField("BDAY:", rawText, true);
    if (!ResultParser.isStringOfDigits(birthday, 8)) {
      // No reason to throw out the whole card because the birthday is formatted wrong.
      birthday = null;
    }
    List<String>? urls = AbstractDoCoMoResultParser.matchDoCoMoPrefixedField("URL:", rawText);

    // Although ORG may not be strictly legal in MECARD, it does exist in VCARD and we might as well
    // honor it when found in the wild.
    String? org = AbstractDoCoMoResultParser.matchSingleDoCoMoPrefixedField("ORG:", rawText, true);

    return AddressBookParsedResult(
        ResultParser.maybeWrap(name),
        null,
        pronunciation,
        phoneNumbers,
        null,
        emails,
        null,
        null,
        note,
        addresses,
        null,
        org,
        birthday,
        null,
        urls,
        null);
  }

  static String _parseName(String name) {
    int comma = name.indexOf(',');
    if (comma >= 0) {
      // Format may be last,first; switch it around
      return name.substring(comma + 1) + ' ' + name.substring(0, comma);
    }
    return name;
  }
}