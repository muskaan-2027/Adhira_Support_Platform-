import 'dart:convert';
import 'package:flutter/material.dart';

ImageProvider getImageProvider(String url) {
  if (url.startsWith('data:image')) {
    final base64Str = url.split(',').last;
    return MemoryImage(base64Decode(base64Str));
  } else if (url.startsWith('/9j/') || url.startsWith('iVBORw0K') || url.startsWith('R0lGOD')) {
    return MemoryImage(base64Decode(url));
  } else {
    return NetworkImage(url);
  }
}
