import 'dart:io';

import 'package:flutterclient/api/auth.dart';
import 'package:flutterclient/logging.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart';

class UploadableVideo {
  String id, url;
  UploadableVideo({this.id, this.url});
}

Future<UploadableVideo> requestUpload(String desc, String soundDesc) async {
  var query = await graphqlClient.value.mutate(MutationOptions(
    documentNode: gql("""
      mutation RequestVideoUpload(\$desc: String!, \$soundDesc: String!) {
        request: uploadVideo(desc: \$desc, soundDesc: \$soundDesc) {
          ... on UploadableVideo {id uploadURL}
          ... on APIError {error}
        }
      }
    """),
    variables: {
      "desc": desc,
      "soundDesc": soundDesc,
    },
  ));

  if (query.hasException) {
    throw "Failed to get upload URL: ${query.exception}";
  }

  var request = query.data["request"];
  if (request["error"] != null) {
    throw("Failed to get upload URL: ${request["error"]}");
  }

  return UploadableVideo(
    id: request["id"],
    url: request["uploadURL"],
  );
}

Future<bool> uploadVideo(UploadableVideo builder, String filename) async {
  var res = await put(
    builder.url,
    body: await File(filename).readAsBytes(),
    headers: {"Content-Type": "video/mp4"},
  );

  if (res.statusCode != 200) {
    logger.w("Failed to upload video (${res.statusCode}): ${res.body}");
    return false;
  }

  logger.i("Uploaded video $filename");
  return true;
}
