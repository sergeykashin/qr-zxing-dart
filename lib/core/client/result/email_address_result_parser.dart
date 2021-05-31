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


import '../../result.dart';
import 'email_address_parsed_result.dart';
import 'email_do_co_mo_result_parser.dart';
import 'result_parser.dart';

/**
 * Represents a result that encodes an e-mail address, either as a plain address
 * like "joe@example.org" or a mailto: URL like "mailto:joe@example.org".
 *
 * @author Sean Owen
 */
class EmailAddressResultParser extends ResultParser {

  static final Pattern _COMMA = ",";

  @override
  EmailAddressParsedResult? parse(Result result) {
    String rawText = ResultParser.getMassagedText(result);
    if (rawText.startsWith("mailto:") || rawText.startsWith("MAILTO:")) {
      // If it starts with mailto:, assume it is definitely trying to be an email address
      String hostEmail = rawText.substring(7);
      int queryStart = hostEmail.indexOf('?');
      if (queryStart >= 0) {
        hostEmail = hostEmail.substring(0, queryStart);
      }
      try {
        hostEmail = ResultParser.urlDecode(hostEmail);
      } catch ( iae) { // IllegalArgumentException
        return null;
      }
      List<String>? tos;
      if (hostEmail.isNotEmpty) {
        tos = hostEmail.split(_COMMA);
      }
      Map<String,String>? nameValues = ResultParser.parseNameValuePairs(rawText);
      List<String>? ccs;
      List<String>? bccs;
      String? subject;
      String? body;
      if (nameValues != null) {
        if (tos == null) {
          String? tosString = nameValues["to"];
          if (tosString != null) {
            tos = tosString.split(_COMMA);
          }
        }
        String? ccString = nameValues["cc"];
        if (ccString != null) {
          ccs = ccString.split(_COMMA);
        }
        String? bccString = nameValues["bcc"];
        if (bccString != null) {
          bccs = bccString.split(_COMMA);
        }
        subject = nameValues["subject"];
        body = nameValues["body"];
      }
      return EmailAddressParsedResult(tos, ccs, bccs, subject, body);
    } else {
      if (!EmailDoCoMoResultParser.isBasicallyValidEmailAddress(rawText)) {
        return null;
      }
      return EmailAddressParsedResult(rawText);
    }
  }

}