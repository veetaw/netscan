import 'report.dart';

String? hostFromLink(Uri uri) {
  if (uri.toString().length > 256 ||
      uri.scheme != 'netscan' ||
      uri.host != 'inspect' ||
      uri.userInfo.isNotEmpty ||
      (uri.path != '' && uri.path != '/') ||
      uri.hasFragment ||
      uri.queryParametersAll.length != 1 ||
      uri.queryParametersAll['host']?.length != 1) {
    return null;
  }
  final host = uri.queryParameters['host'];
  return host != null && isPrivateIPv4(host) ? host : null;
}
